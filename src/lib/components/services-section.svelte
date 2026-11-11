<script>
    import { reveal } from "$lib/reveal";
    import { scrollTo } from "$lib/scroll";
    import ActionButton from "./shared/action-button.svelte";
</script>

<section id="services-section">
    <div class="wrapper">
        <div class="header reveal-section from-bottom" use:reveal>
            <!-- <span>Our Services</span> -->
            <h2>What We Offer</h2>
            <p>
                Studio 4 Hair Salon is your ultimate destination for exceptional hair care and styling in Palmerston North. We are dedicated to crafting looks that not only reflect your personality but also keep you on the cutting edge of fashion trends. Whether you're looking for a transformative haircut, vibrant coloring, or meticulous hair treatments, our personalized approach ensures you leave our salon looking and feeling your absolute best.
            </p>
        </div>
        <div class="cards reveal-section from-bottom" use:reveal>
            <div class="card haircut">
                <span class="title">Haircut</span>
            </div>
            <div class="card colours">
                <span class="title">Colours</span>
            </div>
            <div class="card keratin">
                <span class="title">Keratin</span>
            </div>
            <div class="card other">
                <span class="title">Other</span>
            </div>
        </div>
        <div class="actions reveal-section from-bottom" use:reveal>
            <!-- <ActionButton label="Book Your Appointment Now" link="/book" icon={true} /> -->
            <ActionButton label="Meet John" icon="arrow-down"
                onclick={() => scrollTo('john-section')}
            />
        </div>
    </div>
</section>

<style>
    #services-section {
        /* border: 1px solid green; */
        padding: 4rem 0 6rem;
        /* height: 40rem; */
        background-color: var(--color-accent-50);
        /* background-image: url(/images/pattern-001.svg); */
        /* border: 2px solid red; */
        scroll-margin-top: 2em;
    }
    .wrapper {
        width: min(90%, 110rem);
        margin: 0 auto;
        display: flex;
        flex-direction: column;
        gap: 1rem;
    }
    .wrapper > .header {
        display: flex;
        flex-direction: column;
        justify-content: center;
        text-align: center;
        gap: 0.5rem;
    }
    .wrapper > .header > p {
        /* border: 1px solid red; */
        /* letter-spacing: 0.25px; */
        line-height: 1.75rem;
        margin: 0 auto;
        opacity: 0.8;
        width: min(90%, 40rem);
    }
    /* .wrapper > .header > span {
        font-size: 0.875rem;
        opacity: 0.6;
        text-transform: uppercase;
    } */
    .wrapper > .header > h2 {
        font-size: clamp(2rem, 5vw, 2rem);
        font-family: var(--font-serif);
        line-height: clamp(2.5rem, 5vw, 2.5rem);
        /* border: 1px solid red; */
    }
    .wrapper > .cards {
        display: flex;
        flex-direction: column;
        gap: 1.5rem;
    }
    @media (min-width: 40rem) {
        .wrapper > .cards {
            display: grid;
            grid-template-columns: repeat(2, 1fr);
        }
    }
    @media (min-width: 80rem) {
        .wrapper > .cards {
            display: grid;
            grid-template-columns: repeat(4, 1fr);
        }
    }
    .wrapper > .cards > .card {
        /* border: 2px solid var(--color-accent-400); */
        height: 18rem;
        background-size: cover;
        /* background-size: 80%; */
        background-position: 70%;
        /* border: none; */
        /* border-top: 6px solid transparent; */
        cursor: pointer;
        display: flex;
        flex-direction: column;
        justify-content: flex-end;
        text-align: center;
        transition:
            border-color 150ms ease-in-out,
            box-shadow 150ms ease,
            height 150ms ease,
            width 150ms ease,
            transform 150ms ease,
            z-index 150ms ease,
            background-image 150ms ease;
        /* overflow: hidden; */
    }
    /* .wrapper > .cards > .card::after {
        content: '';
        position: absolute;
        bottom: 0;
        left: 0;
        width: 100%;
        height: 3px;
        background-color: var(--accent);
        transform: scaleX(0);
        transform-origin: bottom left;
        transition: transform 150ms ease-in-out;
    } */
    /* .wrapper > .cards > .card:hover {
        border-top: 5px solid var(--accent);
    } */
    /* .wrapper > .cards > .card:hover::after {
        transform: scaleX(1);
    } */
    /* .wrapper > .cards > .card:hover { */
        /* box-shadow: rgba(50, 50, 93, 0.25) 0px 13px 27px -5px, rgba(0, 0, 0, 0.3) 0px 8px 16px -8px; */
        /* box-shadow: rgba(0, 0, 0, 0.35) 0px 5px 15px; */
        /* box-shadow: var(--color-accent-200) 0px 5px 15px; */
        /* transform: scale(1.02); */
        /* z-index: 999; */
    /* } */
    .wrapper > .cards > .card > .title {
        margin-bottom: 1rem;
        color: var(--color-off-white);
        font-family: var(--font-serif);
        font-size: 2rem;
        font-weight: 300;
        letter-spacing: 0.5px;
    }
    .haircut {
        background-image:
            linear-gradient(to bottom, var(--dark-bg-lighter) 0%, var(--dark-bg-lighter) 100%),
            url(/images/haircut-ds.png);
    }
    /* .haircut:hover {
        background-image:
            linear-gradient(to bottom, rgba(0, 0, 0, 0) 50%, rgba(0, 0, 0, 0.5) 90%),
            url(/images/haircut.jpg);
    } */
    .colours {
        background-image:
            linear-gradient(to bottom, var(--dark-bg-lighter) 0%, var(--dark-bg-lighter) 100%),
            url(/images/colour-ds.png);
        /* background-position: 65% !important; */
    }
    /* .colours:hover {
        background-image:
            linear-gradient(to bottom, rgba(0, 0, 0, 0) 70%, rgba(0, 0, 0, 0.5) 90%),
            url(/images/colour.jpg);
        background-position: 65% !important;
    } */
    .keratin {
        background-image:
            linear-gradient(to bottom, var(--dark-bg-lighter) 0%, var(--dark-bg-lighter) 100%),
            url(/images/treatment-ds.png);
        /* background-position: 70% !important; */
    }
    /* .keratin:hover {
        background-image:
            linear-gradient(to bottom, rgba(0, 0, 0, 0) 60%, rgba(0, 0, 0, 0.5) 90%),
            url(/images/treatment.jpg);
        background-position: 70% !important;
    } */
    .other {
        background-image:
            linear-gradient(to bottom, var(--dark-bg-lighter) 0%, var(--dark-bg-lighter) 100%),
            url(/images/makeup-ds.png);
    }
    /* .other:hover {
        background-image:
            linear-gradient(to bottom, rgba(0, 0, 0, 0) 60%, rgba(0, 0, 0, 0.5) 90%),
            url(/images/makeup.jpg);
    } */
    .actions {
        display: flex;
        align-items: center;
        justify-content: center;
        margin-top: 2rem;
    }
</style>