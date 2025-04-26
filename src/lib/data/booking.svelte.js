let bookingData = $state({
    name: '',
    email: '',
    phone: '',
    date: '',
    service: ''
});

export const createBookingData = () => {
    return {
        /**
         * @param {string} value
         */
        /**
         * @param {string} value
         */
        set name (value) { bookingData.name = value || ''; },
        /**
         * @param {string} value
         */
        /**
         * @param {string} value
         */
        set email (value) { bookingData.email = value || ''; },
        /**
         * @param {string} value
         */
        /**
         * @param {string} value
         */
        set phone (value) { bookingData.phone = value || ''; },
        /**
         * @param {string} value
         */
        /**
         * @param {string} value
         */
        set date (value) { bookingData.date = value || ''; },
        /**
         * @param {string} value
         */
        /**
         * @param {string} value
         */
        set service (value) { bookingData.service = value || ''; }
    };
};