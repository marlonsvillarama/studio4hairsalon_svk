import Review001 from '$lib/images/fb/review-001.jpg';
import Review002 from '$lib/images/fb/review-002.jpg';
import Review003 from '$lib/images/fb/review-003.jpg';
import Review006 from '$lib/images/fb/review-006.jpg';
import Review007 from '$lib/images/fb/review-007.jpg';
import Customers001 from '$lib/images/fb/customers-001.jpg';
import Customers002 from '$lib/images/fb/customers-002.jpg';
import Customers003 from '$lib/images/fb/customers-003.jpg';
import Customers005 from '$lib/images/fb/customers-005.jpg';
import Customers006 from '$lib/images/fb/customers-006.jpg';

const reviews = $state([
    {
        author: 'Marielle',
        text: 'John is the best! I have been a loyal customer for 5 years. He has a great eye for hair fashion and style... who puts his heart and soul in his work. The results always makes me happy!'
    },
    {
        author: 'Josefa',
        text: 'I had an amazing experience at Studio 4 Hair Salon with Kuya John! My haircut was exactly what I wanted and the hair spa treatment was so relaxing... I highly recommend for anyone looking for professional hair services without breaking the bank.'
    },
    {
        author: 'Elizah May',
        text: 'Highly recommended hairdresser! I just gave John a brief idea of what I wanted, and he nailed it perfectly. His expertise and attention to detail are impressive. Super satisfied client here...!'
    },
    {
        author: 'Janella',
        text: 'One of the best hairdressers in Palmy. I would recommend him for being approachable and friendly. Got the haircut and hair color I wanted. Thank you Kuya John!'
    },
    {
        author: 'Michael',
        text: 'I am very fussy with my hair and the quality and care is absolutely top-notch! Better than many hairdressers in Auckland! Thank you!!'
    },
]);

const images = $state([
    Review001,
    Customers001,
    Review002,
    Customers002,
    Customers003,
    Review007,
    Customers005,
    Review006,
    Customers006,
    Review003
]);

export const createReviewsData = () => {
    return {
        get list() { return reviews; },
        get images() { return images; }
    };
};