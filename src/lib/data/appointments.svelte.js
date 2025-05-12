let appointments = $state(
    [{
        name: "Customer 1",
        email: "customer1@gmail.com",
        service: 13,
        date: "20250513",
        time: "1000"
    },
    {
        name: "Customer 2",
        email: "customer_02@gmail.com",
        service: 1,
        date: "20250513",
        time: "1400"
    },
    {
        name: "Customer 3",
        email: "XXXXXXXXXXXXXXXXXXXXX",
        service: 12,
        date: "20250514",
        time: "1100"
    }]
);

export const createAppointmentsData = () =>  {
    return {
        get all () { return appointments; },
        // @ts-ignore
        getByDate (dt) {
            if (Object.prototype.toString.call(dt) === '[object Object]') {
                dt = `${dt.getFullYear()}${(dt.getMonth()+1).toString().padStart(2, '0')}${dt.getDate().toString().padStart(2, '0')}`
            }
            
            return appointments.filter(a => a.date === dt);
        }
    }
};