import Haircut from '$lib/images/haircut.jpg';
import Colour from '$lib/images/colour.jpg';
import Treatment from '$lib/images/treatment.jpg';
import Makeup from '$lib/images/makeup.jpg';

const allServices = $state([
    {
        id: 1,
        name: 'Haircut',
        description: 'Haircuts description goes here...',
        image: Haircut,
        services: [
            { id: 1, name: 'Under 16 years old', price: 25 },
            { id: 2, name: 'Men/Women (Gold Card holder)', price: 30 },
            { id: 3, name: 'Men\'s Haircut', price: 35 },
            { id: 4, name: 'Women\'s Haircut with blowdry', price: 40 },
            { id: 5, name: 'Hair Wash (additional)', price: 10 },
            { id: 6, name: 'Hair Iron (additional)', price: 30 }
        ]
    },
    {
        id: 2,
        name: 'Colours',
        description: 'Colours description goes here...',
        image: Colour,
        services: [
            { id: 7, name: 'Root Colour', price: 110 },
            { id: 8, name: 'Hair Colour', price: 110 },
            { id: 9, name: 'With full head foils', price: 220, range: true },
            { id: 10, name: 'With Keratin treatment', price: 270, range: true },
            { id: 11, name: 'Root Colour', price: 110 }
        ]
    },
    {
        id: 3,
        name: 'Treatment',
        description: 'Treatment description goes here...',
        image: Treatment,
        services: [
            { id: 12, name: 'Hair Spa', price: 60 },
            { id: 13, name: 'Keratin', price: 170 },
            { id: 14, name: 'No yellow Keratin', price: 180 },
            { id: 15, name: 'Kerabond', price: 250 },
            { id: 16, name: 'Permanent straightening', price: 250, range: true }
        ]
    },
    {
        id: 4,
        name: 'Other Services',
        description: 'Other Services description goes here...',
        image: Makeup,
        services: [
            { id: 17, name: 'Hair & Make-up', price: 150 },
            { id: 18, name: 'Hair & Make-up (Bride)', price: 200 },
            { id: 19, name: 'Hair styling', price: 60 },
            { id: 20, name: 'Eyebrow tattoo', price: 200 },
            { id: 21, name: 'Eyeliner tattoo', price: 150 }
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
        get list () { return allServices; }
    };
};