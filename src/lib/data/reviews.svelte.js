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
        text: 'I am very fussy with my hair and the quality and care is absolutely top-notch! Better than many hairdressers in Auckland! Thank!!'
    },
]);

export const createReviewsData = () => {
    return {
        get list() { return reviews; }
    };
};