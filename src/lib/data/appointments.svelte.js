import { API_URL } from "./api.svelte";

// let appointments = $state(
//     [{
//         name: "Customer 1",
//         email: "customer1@gmail.com",
//         service: 13,
//         date: "20250515",
//         time: "1000"
//     },
//     {
//         name: "Customer 2",
//         email: "customer_02@gmail.com",
//         service: 1,
//         date: "20250515",
//         time: "1400"
//     },
//     {
//         name: "Customer 3",
//         email: "XXXXXXXXXXXXXXXXXXXXX",
//         service: 12,
//         date: "20250516",
//         time: "1100"
//     }]
// );

export const createAppointmentsData = () =>  {
    return {
        // get all () { return appointments; },
        // @ts-ignore
        // async getByDate (dt) {
        //     if (Object.prototype.toString.call(dt) === '[object Object]') {
        //         dt = `${dt.getFullYear()}${(dt.getMonth()+1).toString().padStart(2, '0')}${dt.getDate().toString().padStart(2, '0')}`
        //     }
            
        //     let apiResponse = await fetch(`${API_URL}?dt=${dt}`);
        //     let appointments = await apiResponse.json();
        //     console.log('appointmentData >> appointments', appointments);

        //     return appointments;
        //     // appointments = jsonResponse;
        //     // return appointments.filter(a => a.dt === dt);
        // }
    }
};