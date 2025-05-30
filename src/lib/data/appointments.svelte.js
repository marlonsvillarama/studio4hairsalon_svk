import { API_URL } from "./api.svelte";

export const appointments = [
    {
        id: '1',
        name: 'Apple Villarama',
        dt: '20250529',
        time: '1030',
        email: 'apple.linson02@yahoo.com',
        phone: '0227000215',
        service: {
            id: '6',
            name: 'Hair and Make-up for bride',
            category: {
                id: '1',
                name: 'Haircut'
            }
        }
    },
    {
        id: '2',
        name: 'Apple Villarama2',
        dt: '20250529',
        time: '1030',
        email: 'apple.linson02@yahoo.com',
        phone: '0227000215',
        service: {
            id: '6',
            name: 'Men/Women (Gold Card Holder)',
            category: {
                id: '1',
                name: 'Haircut'
            }
        }
    },
    {
        id: '3',
        name: 'Apple Villarama3',
        dt: '20250529',
        time: '1030',
        email: 'apple.linson02@yahoo.com',
        phone: '0227000215',
        service: {
            id: '6',
            name: 'Women\'s Haircut with blowdry',
            category: {
                id: '1',
                name: 'Haircut'
            }
        }
    },
    {
        id: '4',
        name: 'Apple Villarama4',
        dt: '20250529',
        time: '1030',
        email: 'apple.linson02@yahoo.com',
        phone: '0227000215',
        service: {
            id: '6',
            name: 'Hair and Make-up for bride',
            category: {
                id: '1',
                name: 'Haircut'
            }
        }
    },
    {
        id: '5',
        name: 'Apple Villarama5',
        dt: '20250529',
        time: '1030',
        email: 'apple.linson02@yahoo.com',
        phone: '0227000215',
        service: {
            id: '6',
            name: 'Hair and Make-up for bride',
            category: {
                id: '1',
                name: 'Haircut'
            }
        }
    },
    {
        id: '6',
        name: 'Apple Villarama6',
        dt: '20250529',
        time: '1030',
        email: 'apple.linson02@yahoo.com',
        phone: '0227000215',
        service: {
            id: '6',
            name: 'Hair and Make-up for bride',
            category: {
                id: '1',
                name: 'Haircut'
            }
        }
    },
    {
        id: '7',
        name: 'Apple Villarama7',
        dt: '20250529',
        time: '1030',
        email: 'apple.linson02@yahoo.com',
        phone: '0227000215',
        service: {
            id: '6',
            name: 'Hair and Make-up for bride',
            category: {
                id: '1',
                name: 'Haircut'
            }
        }
    },
    {
        id: '8',
        name: 'Apple Villarama8',
        dt: '20250529',
        time: '1030',
        email: 'apple.linson02@yahoo.com',
        phone: '0227000215',
        service: {
            id: '6',
            name: 'Hair and Make-up for bride',
            category: {
                id: '1',
                name: 'Haircut'
            }
        }
    },
];

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