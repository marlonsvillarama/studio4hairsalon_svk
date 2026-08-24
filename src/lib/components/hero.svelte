<script></script>

<div class="hero">
    <div class="hero-img"></div>
    <div class="hero-content">
        <header>
            <div class="logo">Studio 4</div>
            <ul>
                <li><a href="/services" title="Services">Services</a></li>
                <li><a href="/gallery" title="Gallery">Gallery</a></li>
                <li><a href="/reviews" title="Reviews">Reviews</a></li>
            </ul>
        </header>
        <div class="slogan">
            <h1>Where <span class="artistry">artistry</span> meets precision</h1>
            <p>Experience hair care like never before right in the heart of Palmerston North.</p>
            <!-- <div class="contact-info">
                <div class="row">
                    <i class="ph-thin ph-phone"></i>
                    <span>(06) 353-5678</span>
                </div>
                <div class="row">
                    <i class="ph-thin ph-device-mobile"></i>
                    <span>(022) 188-5240</span>
                </div>
            </div> -->
            <a href="/book" title="Book Now" class="cta">Book Now</a>
        </div>
        <div class="proof">
            <div class="rating">
                <p>Great service. Great ambience. A salon that will surely put a smile on your face.</p>
                <div class="stars">
                    {#each { length: 5 } as _}
                    <i class="ph-fill ph-star" size={24}></i>
                    {/each}
                    <span class="reviewer">Aileen C.</span>
                </div>
            </div>
        </div>
    </div>
</div>

<style>
    .hero {
        min-height: 100vh;
        min-width: 100vw;
        position: relative;
    }
    .hero-img {
        background-image:
            linear-gradient(to right, rgba(0, 0, 0, 0.9) 30%, transparent 100%),
            url('/images/hero.jpg');
        background-size: 140%;
        background-position: 28% 28%;
        height: 100vh;
        width: 100vw;
    }
    .hero-content {
        position: absolute;
        z-index: 999;
        top: 50%;
        left: 50%;
        height: 90vh;
        width: min(95%, 110rem);
        padding: 0;
        /* border: 2px solid red; */
        /* padding: 1rem 3rem; */
        display: flex;
        flex-direction: column;
        justify-content: space-between;
        transform: translateX(-50%) translateY(-50%);
    }
    .hero-content > header {
        display: flex;
        align-items: center;
        /* justify-content: space-between; */
        gap: 3rem;
    }
    .hero-content > header > .logo {
        color: var(--color-accent-500);
        font-family: var(--font-logo);
        font-size: 3rem;
    }
    .hero-content > header > ul {
        list-style-type: none;
        display: flex;
        align-items: center;
        gap: 2rem;
        transform: translateY(-20%);
        color: var(--color-off-white);
    }
    .hero-content > header > ul > li > a {
        border-bottom: 2px solid transparent;
        font-size: 0.875rem;
        letter-spacing: 0.5px;
        opacity: 0.7;
        padding-bottom: 0.25rem;
        transition: border-bottom 150ms ease, color 150ms ease;
    }
    .hero-content > header > ul > li > a:hover {
        border-bottom: 2px solid var(--color-accent-500);
        opacity: 1;
    }
    .hero-content > .slogan {
        display: flex;
        flex-direction: column;
        /* gap: 0rem; */
        align-items: flex-start;
    }
    .hero-content > .slogan > h1 {
        font-size: 3.5rem;
        font-weight: 100;
        color: var(--color-off-white);
        letter-spacing: -0.25px;
    }
    .hero-content > .slogan > h1 > .artistry {
        color: var(--color-accent-500);
        /* font-weight: 300; */
    }
    .hero-content > .slogan > p {
        color: var(--color-off-white);
        font-weight: 300;
        opacity: 0.7;
        margin-bottom: 1rem;
    }
    .contact-info {
        margin-bottom: 1rem;
    }
    .contact-info > .row {
        display: flex;
        align-items: center;
        gap: 0.5rem;
        color: var(--color-off-white);
        opacity: 0.7;
    }
    .contact-info > .row > i {
        font-size: 1.5rem;
    }
    .hero-content > .slogan > .cta {
        background-color: var(--color-accent-600);
        border-radius: 0.25rem;
        color: var(--color-off-white);
        cursor: pointer;
        padding: 0.75rem 1.5rem;
        transition: background-color 150ms ease;
    }
    .hero-content > .slogan > .cta:hover {
        background-color: var(--color-accent-700);
    }
    .rating {
        display: flex;
        flex-direction: column;
        align-items: flex-start;
        gap: 0.25rem;
        /* margin-bottom: 2rem; */
    }
    .rating > p {
        color: var(--color-off-white);
        font-style: italic;
    }
    /* .rating > p::before,
    .rating > p::after {
        content: "\"";
    } */
    .rating > .stars {
        display: flex;
        align-items: center;
        gap: 0.25rem;
    }
    .rating > .stars > i {
        color: var(--color-accent-400);
        font-size: 1rem;
    }
    .rating > .stars > .reviewer {
        margin-left: 1rem;
        color: var(--color-off-white);
        opacity: 0.7;
    }
</style>
