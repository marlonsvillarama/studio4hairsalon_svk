let adminData = $state({
    appointment: null,
    listDisplay: false,
    selectedDate: new Date()
});

export const createAdminData = () => {
    return {
        get appointment () { return adminData.appointment; },
        get listDisplay () { return adminData.listDisplay; },
        get selectedDate () { return adminData.selectedDate; },

        set appointment (value) { adminData.appointment = value; },
        set listDisplay (value) { adminData.listDisplay = value; },
        set selectedDate (value) { adminData.selectedDate = value; },

        clear () {
            adminData = {
                appointment: null,
                listDisplay: false,
                selectedDate: new Date()
            };
        }
    };
};