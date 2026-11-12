<script>
    import { reveal } from "$lib/reveal";
    import { scrollTo } from "$lib/scroll";
    import Logo from "./logo.svelte";
    import ActionButton from "./action-button.svelte";

    const scrollToServices = () => {
        let servicesSection = document.getElementById('services-section');
        servicesSection.scrollIntoView({ behavior: 'smooth' });
    };
</script>

<div class="hero">
    <div class="hero-img"></div>
    <div class="hero-content">
        <!-- <div></div> -->
        <!-- <header> -->
            <!-- <Logo /> -->
            <!-- <div class="logo">Studio4</div> -->
            <!-- <ul>
                <li><a href="/services" title="Services">Services</a></li>
                <li><a href="/gallery" title="Gallery">Gallery</a></li>
                <li><a href="/reviews" title="Reviews">Reviews</a></li>
            </ul> -->
        <!-- </header> -->
        <div class="slogan">
            <h1>
                Where <span class="artistry">artistry</span> meets precision
            </h1>
            <p>
                Experience hair care like never before right in the heart of Palmerston North.
            </p>
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

        <div class="actions">
            <ActionButton label="Start Here" icon="arrow-down"
                onclick={() => scrollTo('services-section')}
            />
            <!-- <a href="/book" title="Book Now" class="cta main">
                Book Now
                <i class="ph ph-arrow-circle-right"></i>
            </a> -->
            <!-- <a href="/book" title="Book Now" class="cta">
                Our Services
            </a> -->
        </div>
        <!-- <div class="proof"> -->
            <!-- <div class="rating">
                <p>Great service. Great ambience. A salon that will surely put a smile on your face.</p>
                <div class="stars">
                    {#each { length: 5 } as _}
                    <i class="ph-fill ph-star" size={24}></i>
                    {/each}
                    <span class="reviewer">Aileen C.</span>
                </div>
            </div> -->
        <!-- </div> -->
    </div>
</div>

<style>
    .hero {
        /* border: 1px solid green; */
        /* height: 100vh; */
        min-height: 100vh;
        /* min-width: 100vw; */
        width: 100%;
        padding: 0;
        position: relative;
    }
    .hero-img {
        background-image:
            linear-gradient(to right, rgba(0, 0, 0, 0.6) 30%, rgba(0, 0, 0, 0.6) 70%),
            url('/images/hero.jpg');
        /* background-size: 140%; */
        background-size: cover;
        background-position: 50% center;
        /* background-position: 28% 28%; */
        inset: 0;
        height: 100vh;
        width: 100vw;
        position: absolute;
        z-index: -1;
    }
    @media (min-width: 60rem) {
        .hero-img {
            background-image:
                linear-gradient(to right, rgba(0, 0, 0, 0.6) 0%, rgba(0, 0, 0, 0.3) 100%),
                url('/images/hero.jpg');
            background-size: cover;
            background-position: center 28%;
        }
    }
    .hero-content {
        position: relative;
        /* z-index: 999; */
        /* top: 50%; */
        /* left: 50%; */
        /* height: 90vh; */
        height: 100vh;
        width: 90%;
        max-width: 110rem;
        margin: 0 auto;
        padding: 4rem 0;
        /* border: 1px solid red; */
        /* padding: 1rem 3rem; */
        display: flex;
        flex-direction: column;
        align-items: center;
        justify-content: center;
        gap: 2.5rem;
        /* justify-content: space-between; */
        /* transform: translateX(-50%) translateY(-50%); */
    }
    /* .hero-content > header {
        display: flex;
        align-items: center;
        gap: 3rem;
    } */
    /* .hero-content > header > .logo {
        color: var(--color-accent-500);
        font-family: var(--font-logo);
        font-size: 3rem;
    } */
    /* .hero-content > header > ul {
        list-style-type: none;
        display: flex;
        align-items: center;
        gap: 2rem;
        transform: translateY(-20%);
        color: var(--color-off-white);
    } */
    /* .hero-content > header > ul > li > a {
        border-bottom: 2px solid transparent;
        font-size: 0.875rem;
        letter-spacing: 0.5px;
        opacity: 0.7;
        padding-bottom: 0.25rem;
        transition: border-bottom 150ms ease, color 150ms ease;
    } */
    /* .hero-content > header > ul > li > a:hover {
        border-bottom: 2px solid var(--color-accent-500);
        opacity: 1;
    } */
    .hero-content > .slogan {
        /* border: 1px solid red; */
        display: flex;
        flex-direction: column;
        /* margin-top: 2rem; */
        /* gap: 2rem; */
        align-items: center;
    }
    .hero-content > .slogan > h1 {
        /* font-size: 3.5rem; */
        /* font-weight: 100; */
        /* border: 1px solid red; */
        color: var(--color-off-white);
        font: 100 clamp(3rem, 8vw, 4.5rem) var(--font-default);
        letter-spacing: -0.25px;
        line-height: clamp(3.25rem, 8vw, 4.5rem);
        text-box: trim-both cap alphabetic;
        /* width: 75%; */
        text-align: center;
        margin: 0 auto;
    }
    .hero-content > .slogan > h1 > .artistry {
        color: var(--color-accent-500);
        font-weight: 200;
    }
    .hero-content > .slogan > p {
        color: var(--color-off-white);
        font-weight: 400;
        opacity: 0.8;
        text-align: center;
        margin-top: 1.25rem;
    }
    /* .contact-info {
        margin-bottom: 1rem;
    } */
    /* .contact-info > .row {
        display: flex;
        align-items: center;
        gap: 0.5rem;
        color: var(--color-off-white);
        opacity: 0.7;
    } */
    /* .contact-info > .row > i {
        font-size: 1.5rem;
    } */
    .hero-content > .actions {
        display: flex;
        flex-direction: column;
        align-items: center;
        justify-content: center;
        gap: 1rem;
    }
    @media (min-width: 40rem) {
        .hero-content > .actions {
            flex-direction: row;
        }
    }
    /* .hero-content > .slogan > .actions > .cta { */
        /* background-color: var(--color-accent-600); */
        /* border-radius: 0.25rem; */
        /* background-color: var(--color-accent-400); */
        /* border: 1px solid var(--color-accent-400);
        color: var(--white);
        cursor: pointer;
        font-weight: 600;
        padding: 0.75rem 2rem;
        display: flex;
        align-items: center;
        gap: 0.5rem; */
        /* transition: padding-right 150ms ease; */
        /* position: relative;
        transition: background-color 150ms ease-in-out, border-color 150ms ease-in-out;
    } */
    /* .hero-content > .slogan > .actions > .cta.main {
        background-color: var(--color-accent-400); */
        /* background: linear-gradient(120deg, var(--color-accent-600) 0%, var(--color-accent-400) 100%); */
        /* border: 1px solid var(--color-accent-400);
        color: var(--darkest);
    } */
    /* .hero-content > .slogan > .actions > .cta > i {
        font-size: 1.5rem; */
        /* content: '→'; */
        /* color: var(--white); */
        /* opacity: 0; */
        /* position: absolute;
        border: 1px solid red;
        right: 10px;
        top: 50%;
        transform: translateX(-50%);
        transition: opacity 0.3s ease, right 0.3s ease; */
        /* background-color: var(--color-accent-700); */
        /* border-left: 4px solid var(--color-accent-700); */
    /* } */
    /* .hero-content > .slogan > .actions > .cta:hover {
        background-color: var(--accent-bg-pale);
        border-color: var(--color-accent-400);
    } */
    /* .hero-content > .slogan > .actions > .cta.main:hover {
        background-color: var(--color-accent-500); */
        /* background: linear-gradient(120deg, var(--color-accent-600) 0%, var(--color-accent-500) 100%); */
        /* padding-right: 3.5rem; */
        /* display: block;
        opacity: 100; */
    /* } */
    /* .hero-content > .slogan > .cta:hover::after {
        opacity: 1;
        right: 1.125rem;
    } */
    .rating {
        display: flex;
        flex-direction: column;
        align-items: center;
        gap: 0.25rem;
        text-align: center;
        margin-top: 2rem;
    }
    .rating > p {
        color: var(--color-off-white);
        font-style: italic;
    }
    .rating > p::before,
    .rating > p::after {
        content: "\"";
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
