import { getContext, setContext } from "svelte";
import { getSupabase, errorCode } from "$lib/supabase";
import { loadCatalogue, priceFor, formatDuration } from "./services";
import { submitBooking } from "./booking";
import { loadSchedule, refreshBusy, getOpenDays, getSlots, formatTime, isMonthLoaded, monthKey, salonToday, addDays } from "./availability";

const STORAGE_KEY = 'studio4.booking';
const CONFIRMED_KEY = 'studio4.booking.confirmed';

export const STEPS = [
    { id: 'services', label: 'Services' },
    { id: 'appointment', label: 'Date & time' },
    { id: 'details', label: 'Your details' },
    { id: 'review', label: 'Confirm' },
];

const emptyClient = () => ({ firstName: '', lastName: '', phone: '', email: '', notes: '' });

// Loose NZ-friendly phone check: 7–15 digits once spaces, dashes, brackets
// and a leading + are removed. The database normalises it properly.
const isPhone = (v) => /^\+?\d{7,15}$/.test(v.replace(/[\s\-()]/g, ''));
const isEmail = (v) => /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(v);
// "+64221885240" → "0221885240", the way NZ clients write their own number.
const nationalPhone = (e164) => e164?.startsWith('+64') ? `0${e164.slice(3)}` : (e164 || '');

export class CartState {
    // What's loaded from Supabase.
    catalogue = $state({ categories: [], services: [] });
    schedule = $state(null);
    loadState = $state('loading');   // loading | ready | error
    loadError = $state('');

    // Signed in with Google (optional).
    account = $state(null);          // { email } once linked to s4_clients
    authNotice = $state('');

    // The booking being built.
    step = $state(0);
    services = $state([]);
    date = $state('');               // "YYYY-MM-DD", salon time
    time = $state('');               // "HH:MM", salon time
    client = $state(emptyClient());
    goldCard = $state(false);
    status = $state('idle');         // idle | submitting | error | done
    errorMessage = $state('');
    reference = $state('');
    showErrors = $state(false);
    serverErrors = $state({});       // field errors that only the server can know (e.g. phone_in_use)
    focusRequest = $state(0);
    timeNotice = $state('');
    confirmation = $state(null);

    get currentStep() { return STEPS[this.step] }
    get isLastStep() { return this.step === STEPS.length - 1 }
    get timezone() { return this.schedule?.timezone || 'Pacific/Auckland' }

    get selectedItems() {
        return this.services.map(id => this.catalogue.services.find(s => s.id === id)).filter(Boolean);
    }
    priceOf = (service) => priceFor(service, this.goldCard);
    usesGoldCard = (service) => this.goldCard && service.goldCardPrice != null;

    get totalPrice() { return this.selectedItems.reduce((sum, s) => sum + this.priceOf(s), 0) }
    get totalDuration() { return this.selectedItems.reduce((sum, s) => sum + s.duration, 0) }
    get hasVariablePrice() { return this.selectedItems.some(s => s.range) }
    get onlyAddOns() { return this.services.length > 0 && this.selectedItems.every(s => s.addon) }

    /** Bookable days in a month ("YYYY-MM"); load it first with loadMonth. */
    openDaysIn = (key) => getOpenDays(this.schedule, key);
    isMonthLoaded = (key) => isMonthLoaded(this.schedule, key);
    /** The first month that can have bookable days (tomorrow's). */
    get firstMonth() { return monthKey(addDays(salonToday(this.schedule), 1)) }
    slotsFor = (isoDate) => getSlots(this.schedule, isoDate, this.totalDuration, this.visitGaps);

    /** The visit's own waiting periods, with services in the salon's order (as the database does). */
    get visitGaps() {
        const { categories, services } = this.catalogue;
        const rank = (s) => categories.findIndex(c => c.id === s.category) * 10_000 + services.indexOf(s);
        let at = 0;
        const gaps = [];
        for (const s of this.selectedItems.toSorted((a, z) => rank(a) - rank(z))) {
            if (s.wait) gaps.push({ start: at + s.wait.after, end: at + s.wait.after + s.wait.length });
            at += s.duration;
        }
        return gaps;
    }

    get detailErrors() {
        const c = this.client;
        const errors = { ...this.serverErrors };
        if (!c.firstName.trim()) errors.firstName = 'Please enter your first name.';
        // Phone and email are both optional, but John needs one way to reach the client.
        const email = this.account ? this.account.email : c.email.trim();
        if (!c.phone.trim() && !email) {
            errors.phone = 'Add a mobile number or an email so I can reach you.';
            errors.email = 'Add an email or a mobile number.';
        }
        if (c.phone.trim() && !isPhone(c.phone)) errors.phone = 'That number looks too short. Try including the area code, e.g. 022 188 5240.';
        if (!this.account && c.email.trim() && !isEmail(c.email.trim())) errors.email = 'Check the email address, e.g. name@example.com.';
        return errors;
    }

    get blocker() {
        switch (this.currentStep.id) {
            case 'services':
                if (!this.services.length) return 'Choose at least one service to continue.';
                if (this.onlyAddOns) return 'Extras like a hair wash go with another service. Please add a main service too.';
                return '';
            case 'appointment':
                if (!this.date) return 'Choose a day.';
                if (!this.time) return 'Choose a time.';
                return '';
            case 'details':
                return Object.keys(this.detailErrors).length ? 'Fill in the highlighted fields.' : '';
            default:
                return '';
        }
    }

    // ─── loading ────────────────────────────────────────────────────────

    /** Load catalogue + calendar, restore saved progress, pick up a Google session. */
    init = async () => {
        this.loadState = 'loading';
        this.loadError = '';
        try {
            const [catalogue, schedule] = await Promise.all([loadCatalogue(), loadSchedule()]);
            this.catalogue = catalogue;
            this.schedule = schedule;
            this.loadState = 'ready';
        } catch (err) {
            console.error('[booking] could not load', err);
            this.loadState = 'error';
            this.loadError = "I couldn't load the booking calendar. Please check your connection and try again.";
            return;
        }

        await this.restore();

        const params = new URLSearchParams(window.location.search);
        if (params.get('error') || params.get('error_description')) {
            this.authNotice = "Google sign-in didn't finish. You can still enter your details below.";
        }

        const sb = getSupabase();
        sb.auth.onAuthStateChange((event) => {
            // Never await Supabase calls inside this callback; defer instead.
            if (event === 'SIGNED_IN' || event === 'SIGNED_OUT' || event === 'INITIAL_SESSION') {
                setTimeout(() => this.loadAccount(), 0);
            }
        });
    }

    /** Make sure busy times for a month ("YYYY-MM") are loaded. */
    loadMonth = async (key) => {
        if (!this.schedule || this.isMonthLoaded(key)) return true;
        try {
            await refreshBusy(this.schedule, [key]);
            return true;
        } catch {
            return false;
        }
    }

    /**
     * The first bookable day from tomorrow, looking up to a year ahead.
     * Returns '' when nothing is free (or the calendar can't be loaded).
     */
    firstOpenDay = async () => {
        if (!this.schedule) return '';
        let key = this.firstMonth;
        for (let i = 0; i < 12; i++) {
            if (!(await this.loadMonth(key))) return '';
            const days = this.openDaysIn(key);
            if (days.length) return days[0];
            key = monthKey(addDays(`${key}-01`, 32));
        }
        return '';
    }

    /** Re-check busy times (e.g. when the client comes back to the calendar). */
    refreshAvailability = async () => {
        if (!this.schedule) return;
        try {
            await refreshBusy(this.schedule);
            this.revalidateTime();
        } catch { /* keep the last known calendar */ }
    }

    // ─── Google account ─────────────────────────────────────────────────

    signInWithGoogle = async () => {
        this.authNotice = '';
        this.persist();  // the cart survives the round trip through Google
        const { error } = await getSupabase().auth.signInWithOAuth({
            provider: 'google',
            options: { redirectTo: `${window.location.origin}/book?resume=details` }
        });
        if (error) this.authNotice = "Google sign-in didn't start. You can still enter your details below.";
    }

    signOut = async () => {
        await getSupabase().auth.signOut();
        this.account = null;
        this.client.email = '';
        this.persist();
    }

    loadAccount = async () => {
        const sb = getSupabase();
        const { data: { session } } = await sb.auth.getSession();
        if (!session) {
            this.account = null;
            return;
        }
        const { data: profile, error } = await sb.rpc('s4_link_my_client');
        if (error) {
            console.error('[booking] could not link account', error);
            this.authNotice = "You're signed in, but I couldn't load your details. Please enter them below.";
            return;
        }
        this.account = { email: profile.email };
        // Fill only what the client hasn't typed already.
        const c = this.client;
        if (!c.firstName.trim() && profile.first_name) c.firstName = profile.first_name;
        if (!c.lastName.trim() && profile.last_name) c.lastName = profile.last_name;
        if (!c.phone.trim() && profile.phone) c.phone = nationalPhone(profile.phone);
        c.email = profile.email || '';
        if (profile.has_gold_card) this.goldCard = true;
        this.persist();
    }

    // ─── editing ────────────────────────────────────────────────────────

    isSelected = (id) => this.services.includes(id);

    toggleService = (id) => {
        this.services = this.isSelected(id)
            ? this.services.filter(s => s !== id)
            : [...this.services, id];
        this.revalidateTime();
        this.persist();
    }

    removeService = (id) => {
        this.services = this.services.filter(s => s !== id);
        this.revalidateTime();
        this.persist();
    }

    // Keep the chosen time when it still fits; otherwise drop it and say why.
    revalidateTime() {
        if (!this.date || !this.time) return;
        if (this.slotsFor(this.date).includes(this.time)) return;
        this.timeNotice = `${formatTime(this.time)} is no longer free for a ${formatDuration(this.totalDuration)} visit. Please choose another time.`;
        this.time = '';
    }

    setGoldCard = (value) => {
        this.goldCard = !!value;
        this.persist();
    }

    selectDate = (iso) => {
        if (this.date !== iso) this.time = '';
        this.date = iso;
        this.timeNotice = '';
        this.persist();
    }

    selectTime = (hhmm) => {
        this.time = hhmm;
        this.timeNotice = '';
        this.persist();
    }

    updateClient = (field, value) => {
        this.client[field] = value;
        if (this.serverErrors[field]) {
            const { [field]: _, ...rest } = this.serverErrors;
            this.serverErrors = rest;
        }
        this.persist();
    }

    // ─── navigation ─────────────────────────────────────────────────────

    next = () => {
        if (this.blocker) {
            this.showErrors = true;
            this.focusRequest += 1;
            return false;
        }
        this.showErrors = false;
        if (!this.isLastStep) this.step += 1;
        this.persist();
        return true;
    }

    back = () => {
        this.showErrors = false;
        if (this.step > 0) this.step -= 1;
        this.persist();
    }

    goTo = (stepId) => {
        const index = STEPS.findIndex(s => s.id === stepId);
        if (index >= 0 && index <= this.step) this.step = index;
        this.persist();
    }

    // ─── booking ────────────────────────────────────────────────────────

    submit = async () => {
        if (this.status === 'submitting') return;
        this.status = 'submitting';
        this.errorMessage = '';
        try {
            const result = await submitBooking({
                services: [...this.services],
                date: this.date,
                time: this.time,
                timezone: this.timezone,
                goldCard: this.goldCard,
                client: { ...this.client }
            });
            this.reference = result.reference;
            this.confirmation = {
                name: this.client.firstName,
                email: this.account?.email || this.client.email || '',
                date: this.date,
                time: this.time,
                duration: this.totalDuration,
                total: result.total,                 // the server's price is the real price
                variablePrice: result.variablePrice,
                services: this.selectedItems.map(s => this.usesGoldCard(s) ? `${s.name} (Gold Card)` : s.name),
                reference: result.reference
            };
            this.status = 'done';
            this.clearStorage();
            try { sessionStorage.setItem(CONFIRMED_KEY, JSON.stringify(this.confirmation)); } catch { /* ignore */ }
        }
        catch (err) {
            await this.recover(err);
        }
    }

    // Send the client to the step that can fix the problem.
    async recover(err) {
        const code = err?.code || errorCode(err);
        if (['slot_taken', 'too_soon', 'outside_hours'].includes(code)) {
            const lost = this.time;
            await this.refreshAvailability();
            this.time = '';
            this.timeNotice = code === 'slot_taken'
                ? `Someone has just booked ${formatTime(lost)}. Please choose another time.`
                : `${err.message} Please choose another time.`;
            this.status = 'idle';
            this.goTo('appointment');
            return;
        }
        if (code === 'phone_in_use' || code === 'invalid_phone' || code === 'invalid_details' || code === 'contact_required') {
            this.serverErrors = code === 'invalid_details'
                ? { firstName: err.message }
                : { phone: err.message };
            this.status = 'idle';
            this.showErrors = true;
            this.goTo('details');
            this.focusRequest += 1;
            return;
        }
        if (code === 'invalid_services') {
            try { this.catalogue = await loadCatalogue(); } catch { /* keep the old list */ }
            this.services = this.services.filter(id => this.catalogue.services.some(s => s.id === id));
            this.status = 'idle';
            this.goTo('services');
            return;
        }
        this.status = 'error';
        this.errorMessage = err?.message || 'Something went wrong while booking.';
    }

    startOver = () => {
        this.step = 0;
        this.services = [];
        this.date = '';
        this.time = '';
        const email = this.account?.email || '';
        this.client = { ...emptyClient(), email };
        this.goldCard = false;
        this.confirmation = null;
        this.timeNotice = '';
        this.serverErrors = {};
        this.status = 'idle';
        this.reference = '';
        this.clearStorage();
        try { sessionStorage.removeItem(CONFIRMED_KEY); } catch { /* ignore */ }
    }

    // ─── persistence ────────────────────────────────────────────────────

    persist() {
        try {
            sessionStorage.setItem(STORAGE_KEY, JSON.stringify({
                step: this.step, services: this.services, date: this.date,
                time: this.time, client: this.client, goldCard: this.goldCard
            }));
        } catch { /* storage unavailable: progress just won't survive a reload */ }
    }

    async restore() {
        try {
            const confirmed = JSON.parse(sessionStorage.getItem(CONFIRMED_KEY) || 'null');
            if (confirmed) {
                this.confirmation = confirmed;
                this.reference = confirmed.reference;
                this.status = 'done';
                return true;
            }
            const saved = JSON.parse(sessionStorage.getItem(STORAGE_KEY) || 'null');
            if (!saved) return false;
            this.services = (saved.services || []).filter(id => this.catalogue.services.some(s => s.id === id));
            this.date = saved.date || '';
            this.time = saved.time || '';
            this.client = { ...emptyClient(), ...(saved.client || {}) };
            this.goldCard = !!saved.goldCard;
            if (this.date) await this.loadMonth(monthKey(this.date));
            if (this.date && !this.openDaysIn(monthKey(this.date)).includes(this.date)) this.date = '';
            if (!this.date || !this.slotsFor(this.date).includes(this.time)) this.time = '';
            const target = Math.min(Math.max(saved.step || 0, 0), STEPS.length - 1);
            this.step = 0;
            while (this.step < target && !this.blocker) this.step += 1;
            return true;
        } catch {
            return false;
        }
    }

    clearStorage() {
        try { sessionStorage.removeItem(STORAGE_KEY); } catch { /* ignore */ }
    }
}

const CART_KEY = Symbol('CART');
export const setCartState = () => setContext(CART_KEY, new CartState());
export const getCartState = () => getContext(CART_KEY);
