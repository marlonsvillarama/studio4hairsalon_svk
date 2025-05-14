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

export const unparseTime = (dt) => {
    if (!dt) { return ''; }
    
    return dt.getHours().toString().padStart(2, '0') +
        dt.getMinutes().toString().padStart(2, '0');
};

export const unparseDate = (date) => {
    if (!date) { return ''; }

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
        get data () {
            return {
                date: unparseDate(bookingData.date),
                email: bookingData.email,
                name: bookingData.name,
                phone: bookingData.phone,
                service: bookingData.service,
                time: bookingData.time
            };
        },
        
        set date (value) { bookingData.date = value; },
        set email (value) { bookingData.email = value || ''; },
        set name (value) { bookingData.name = value || ''; },
        set phone (value) { bookingData.phone = value || ''; },
        set service (value) { bookingData.service = value || ''; },
        set time (value) { bookingData.time = value || ''; },

        reset () {
            bookingData.date = null;
            bookingData.email = '';
            bookingData.name = '';
            bookingData.phone = '';
            bookingData.service = '';
            bookingData.time = '';
        }
    };
};