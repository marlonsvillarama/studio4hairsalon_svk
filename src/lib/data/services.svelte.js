import Haircut from '$lib/images/haircut.jpg';
import Colour from '$lib/images/colour.jpg';
import Treatment from '$lib/images/treatment.jpg';
import Makeup from '$lib/images/makeup.jpg';

let activeCategory = $state({});
let activeService = $state({});
const allServices = $state([
    {
        id: 1,
        link: 'haircut',
        name: 'Haircut',
        description: 'Haircuts description goes here...',
        image: Haircut,
        services: [
            { id: 1, name: 'Under 16 years old', description: 'Under 16 years old description...', duration: 30, price: 25 },
            { id: 2, name: 'Men/Women (Gold Card holder)', description: 'Men/Women (Gold Card holder) description...', duration: 30, price: 30 },
            { id: 3, name: 'Men\'s Haircut', description: 'Men\'s Haircut description...', duration: 30, price: 35 },
            { id: 4, name: 'Women\'s Haircut with blowdry', description: 'Women\'s Haircut with blowdry description...', duration: 30, price: 40 },
            { id: 5, name: 'Hair Wash (additional)', description: 'Hair Wash (additional) description...', duration: 30, price: 10 },
            { id: 6, name: 'Hair Iron (additional)', description: 'Hair Iron (additional) description...', duration: 30, price: 30 }
        ]
    },
    {
        id: 2,
        link: 'colours',
        name: 'Colours',
        description: 'Colours description goes here...',
        image: Colour,
        services: [
            { id: 7, name: 'Root Colour', description: 'Root Colour description...', duration: 60, price: 110 },
            { id: 8, name: 'Hair Colour', description: 'Hair Colour description...', duration: 60, price: 110 },
            { id: 9, name: 'With Full Head Foils', description: 'With Full Head Foils description...', duration: 60, price: 220, range: true },
            { id: 10, name: 'With Keratin treatment', description: 'With Keratin treatment description...', duration: 60, price: 270, range: true },
            { id: 11, name: 'Full Head Foil with Toner', description: 'Full Head Foil with Toner description...', duration: 60, price: 110 }
        ]
    },
    {
        id: 3,
        link: 'treatment',
        name: 'Treatment',
        description: 'Treatment description goes here...',
        image: Treatment,
        services: [
            { id: 12, name: 'Hair Spa', description: 'Hair Spa description...', duration: 90, price: 60 },
            { id: 13, name: 'Keratin', description: 'Keratin description...', duration: 90, price: 170 },
            { id: 14, name: 'No yellow Keratin', description: 'No yellow Keratin description...', duration: 90, price: 180 },
            { id: 15, name: 'Kerabond', description: 'Kerabond description...', duration: 90, price: 250 },
            { id: 16, name: 'Permanent straightening', description: 'Permanent straightening description...', duration: 90, price: 250, range: true }
        ]
    },
    {
        id: 4,
        link: 'other',
        name: 'Other Services',
        description: 'Other Services description goes here...',
        image: Makeup,
        services: [
            { id: 17, name: 'Hair and Make-up', description: 'Hair and Make-up description...', duration: 120, price: 150 },
            { id: 18, name: 'Hair and Make-up (Bride)', description: 'Hair and Make-up (Bride) description...', duration: 120, price: 200 },
            { id: 19, name: 'Hair styling', description: 'Hair styling description...', duration: 120, price: 60 },
            { id: 20, name: 'Eyebrow tattoo', description: 'Eyebrow tattoo description...', duration: 120, price: 200 },
            { id: 21, name: 'Eyeliner tattoo', description: 'Eyeliner tattoo description...', duration: 120, price: 150 }
        ]
    }
]);

export const createServicesData = () => {
    return {
        // get categories () {
        //     return allServices.map(d => {
        //         return { id: d.id, name: d.name };
        //     });
        // },
        get list () { return allServices; },
        get activeCategory () { return activeCategory; },
        get activeService () { return activeService; },
        get services () {
            /**
             * @type {never[]}
             */
            let output = allServices.reduce((a, b) => {
                let mappedServices = b.services.map(s => {
                    return {
                        ...s,
                        category: { id: b.id, name: b.name }
                    }
                });

                // @ts-ignore
                a = a.concat(mappedServices);
                return a;
            }, []);
            return output;
        },

        set activeService (value) {
            activeService = value;
            // @ts-ignore
            activeCategory = allServices.find(d => d.services.map(s => s.id).indexOf(activeService.id) >= 0);
        },

        // @ts-ignore
        getServiceById (id) {
            if (!id) { return null; }
            // @ts-ignore
            let svc = this.services.find(s => s.id === id);
            console.log(`getServiceById id = ${id}`, svc);
            return svc;
        },

        // @ts-ignore
        getServicesById (list) {
            // @ts-ignore
            return this.services.filter(s => list.includes(s.id));
        }
    };
};