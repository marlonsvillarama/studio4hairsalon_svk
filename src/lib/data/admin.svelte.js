let adminData = $state({
    appointment: {},
    listDisplay: false
});

export const createAdminData = () => {
    return {
        get appointment () { return adminData.appointment; },
        get listDisplay () { return adminData.listDisplay; },

        set appointment (value) { adminData.appointment = value; },
        set listDisplay (value) { adminData.listDisplay = value; },

        clear () {
            adminData = {
                appointment: {},
                listDisplay: false
            };
        }
    };
};