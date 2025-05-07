// @ts-nocheck
let bookingData = $state({
    date: null,
    email: '',
    name: '',
    phone: '',
    service: '',
    time: ''
});

export const parseDate = (str) => {
    return new Date(str.slice(0, 4), parseInt(str.slice(4, 6)) - 1, str.slice(6));
};

export const unparseDate = (date) => {
    return date.getFullYear() +
        (date.getMonth() + 1).toString().padStart(2, '0') +
        date.getDate().toString().padStart(2, '0');
};

export const createBookingData = () => {
    return {
        get date () { return bookingData.date; },
        get email () { return bookingData.email; },
        get name () { return bookingData.name; },
        get phone () { return bookingData.phone; },
        get service () { return bookingData.service; },
        get time () { return bookingData.time; },
        
        set date (value) { bookingData.date = value; },
        set email (value) { bookingData.email = value || ''; },
        set name (value) { bookingData.name = value || ''; },
        set phone (value) { bookingData.phone = value || ''; },
        set service (value) { bookingData.service = value || ''; },
        set time (value) { bookingData.time = value || ''; }
    };
};