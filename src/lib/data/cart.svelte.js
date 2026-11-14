import { User } from "./user";
import { getContext, setContext } from "svelte";
import { allServices } from "./services";
import CartServices from "$lib/components/booking-form/cart/cart-services.svelte";
import CartBookingMode from "$lib/components/booking-form/cart/cart-booking-mode.svelte";
// import CartCalendar from "$lib/components/booking-form/cart/cart-calendar.svelte";

export class CartState {
    BOOKING_MODES = [
        {
            id: 1,
            name: 'Book together',
            desc: 'We will find the soonest available date and time for all services.'
        },
        {
            id: 2,
            name: 'Book separately',
            desc: 'Choose a separate date and time for each service.'
        },
    ];
    STEPS = [
        { id: 'services', label: 'Services', content: CartServices },
        { id: 'booking-mode', label: 'Booking Mode', content: CartBookingMode },
        { id: 'calendar', label: 'Date & Time', content: CartBookingMode },
        { id: 'summary', label: 'Summary', content: CartServices }
    ];
    step = $state(1);
    services = $state([]);
    price = $state(0);
    duration = $state(0);
    user = $state(null);
    bookingMode = $state(0);
    activeNav = $state(true);

    constructor (initial = 0) {
        this.step = initial;
        this.services = [];
        this.user = new User();
    }

    get allBookingModes() { return this.BOOKING_MODES }
    get allSteps() { return this.STEPS }
    get currentBookingMode() { return this.bookingMode }
    get currentStep() { return this.step }
    get currentView() { return this.STEPS[this.step] }
    get currentUser() { return this.user }
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

    addService = (id) => { this.services = [ ...this.services, id ]; }

    enableNav = (value = true) => this.activeNav = value;

    removeService = (id) => this.services = this.services.filter(d => d !== id);

    updateBookingMode = (mode = 1) => this.bookingMode = mode;

    updateStep = (inc = 1) => {
        if (this.step === 0 && inc < 0) return;
        if (this.step === this.STEPS.length - 1 && inc > 0) return;

        this.step = this.step + inc;
        console.log('updateStep currentStep ==>', this.step);
    }
}

const CART_KEY = Symbol('CART');
export const setCartState = () => setContext(CART_KEY, new CartState());
export const getCartState = () => getContext(CART_KEY);
