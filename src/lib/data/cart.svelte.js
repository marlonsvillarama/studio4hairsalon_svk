import { getContext, setContext } from "svelte";
import { SvelteDate } from "svelte/reactivity";
import { allServices } from "./services";
import { User } from "./user";
import CartServices from "$lib/components/booking-form/cart/cart-services.svelte";
import CartBookingMode from "$lib/components/booking-form/cart/cart-booking-mode.svelte";
import CartAppointment from "$lib/components/booking-form/cart/cart-appointment.svelte";
// import CartCalendar from "$lib/components/booking-form/cart/cart-calendar.svelte";

export class CartState {
    BOOKING_MODES = [
        {
            id: 'together',
            name: 'Book together',
            desc: 'We will find the soonest available date and time for all services.'
        },
        {
            id: 'separate',
            name: 'Book separately',
            desc: 'Choose a separate date and time for each service.'
        },
    ];
    STEPS = [
        { id: 'services', label: 'Services', content: CartServices },
        { id: 'booking-mode', label: 'Booking Mode', content: CartBookingMode },
        { id: 'appointment', label: 'Date & Time', content: CartAppointment },
        // { id: 'summary', label: 'Summary', content: CartServices }
    ];
    step = $state(1);
    services = $state([]);
    dt = new SvelteDate();
    // price = $state(0);
    // duration = $state(0);
    user = $state(null);
    bookingMode = $state('');
    activeNav = $state(true);

    constructor (initial = 0) {
        this.step = initial;
        this.services = [];
        this.user = new User();
    }

    get allBookingModes() { return this.BOOKING_MODES }
    get allSteps() { return this.STEPS }
    get appointmentDate() { return this.dt }
    get currentBookingMode() { return this.bookingMode }
    get currentStep() { return this.step }
    get currentView() { return this.STEPS[this.step] }
    get currentUser() { return this.user }
    get isNavActive() { return this.activeNav }
    get selectedServices() { return this.services }
    get totalPrice() {
        return this.services.length > 0 ?
            allServices.filter(d => this.services.indexOf(d.id) >= 0).reduce((sum, next) => sum + next.price, 0) :
            0;
    }
    get totalDuration() {
        return this.services.length > 0 ?
            allServices.filter(d => this.services.indexOf(d.id) >= 0).reduce((sum, next) => sum + next.duration, 0) :
            0;
    }
    get data() {
        return {
            services,
            user: this.user?.data
        };
    };

    addService = (id) => {
        this.services = [ ...this.services, id ];
        this.activeNav = this.services.length > 0;
    }

    enableNav = (value = true) => this.activeNav = value;

    removeService = (id) => {
        this.services = this.services.filter(d => d !== id);
        this.activeNav = this.services.length > 0;
    }

    updateBookingMode = (mode = 1) => this.bookingMode = mode;

    updateDate = (value) => {
        this.dt.setUTCFullYear(value.slice(0, 4));
        this.dt.setMonth(parseInt(value.slice(4, 6)));
        this.dt.setDate(parseInt(value.slice(6)));
    }

    updateStep = (inc = 1) => {
        if (this.step === 0 && inc < 0) return;
        if (this.step === this.STEPS.length - 1 && inc > 0) return;
        if (inc > 0 && !this.isNavActive) return;

        if (this.STEPS[this.step].id === 'services') {
            this.step = this.STEPS.findIndex(d => d.id === (this.services.length > 1 ? 'booking-mode' : 'appointment'));
        }
        else if (this.STEPS[this.step].id === 'booking-mode' && inc === 1) {
            this.step = this.STEPS.findIndex(d => d.id === 'summary');
        }
        else if (this.STEPS[this.step].id === 'appointment' && inc === -1) {
            this.step = this.STEPS.findIndex(d => d.id === 'services');
        }
        else {
            this.step = this.step + inc;
        }
        console.log('updateStep currentStep ==>', this.step);
    }

    updateTime = (value) => {
        this.dt.setHours(parseInt(value.slice(0, 2)));
        this.dt.setMinutes(parseInt(value.slice(2)));
    }
}

const CART_KEY = Symbol('CART');
export const setCartState = () => setContext(CART_KEY, new CartState());
export const getCartState = () => getContext(CART_KEY);
