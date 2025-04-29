let bookingData = $state({
    date: null,
    email: '',
    name: '',
    phone: '',
    service: '',
    time: ''
});

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