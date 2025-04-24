import Logo001 from '$lib/images/gallery/logo-001.jpg';
import Haircut001 from '$lib/images/gallery/haircut-001.jpg';
import Haircut002 from '$lib/images/gallery/haircut-002.jpg';
import Haircut003 from '$lib/images/gallery/haircut-003.jpg';
import Haircut004 from '$lib/images/gallery/haircut-004.jpg';
import Haircut005 from '$lib/images/gallery/haircut-005.jpg';
import Haircut006 from '$lib/images/gallery/haircut-006.jpg';
import Haircut007 from '$lib/images/gallery/haircut-007.jpg';
import Colour001 from '$lib/images/gallery/colour-001.jpg';
import Colour002 from '$lib/images/gallery/colour-002.jpg';
import Colour003 from '$lib/images/gallery/colour-003.jpg';
import Colour004 from '$lib/images/gallery/colour-004.jpg';
import Makeup001 from '$lib/images/gallery/makeup-001.jpg';

const images = $state([
    Logo001,
    Colour003,
    Haircut003,
    Haircut006,
    Colour002,
    Haircut001,
    Colour001,
    Haircut004,
    Haircut007,
    Makeup001,
    Haircut002,
    Haircut005,
    Colour004,
]);

export const createGalleryData = () => {
    return {
        get images() { return images; }
    };
};