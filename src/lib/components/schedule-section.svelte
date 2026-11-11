<script>
    import { reveal } from "$lib/reveal";
  import ActionButton from "./shared/action-button.svelte";
</script>

<section id="visit-section">
    <div class="wrapper">
        <div class="hours reveal-section from-left" use:reveal>
            <h2>Visit Us</h2>
            <div class="row reveal-section from-left staggered" use:reveal>
                <i class="ph ph-map-pin"></i>
                <div class="block">
                    <span class="title">Location</span>
                    <p>7 George Street<br/>Palmerston North</p>
                </div>
            </div>
            <div class="row reveal-section from-left staggered" use:reveal>
                <i class="ph ph-phone"></i>
                <div class="block">
                    <span class="title">Phone Number</span>
                    <p>(06) 353-5678</p>
                </div>
            </div>
            <div class="row reveal-section from-left staggered" use:reveal>
                <i class="ph ph-device-mobile"></i>
                <div class="block">
                    <span class="title">Mobile Number</span>
                    <p>(022) 188-5240</p>
                </div>
            </div>
            <div class="row reveal-section from-left staggered" use:reveal>
                <i class="ph ph-calendar-dots"></i>
                <div class="block">
                    <span class="title">Days Open</span>
                    <p>Mondays to Saturdays</p>
                </div>
            </div>
            <div class="row reveal-section from-left staggered" use:reveal>
                <i class="ph ph-clock"></i>
                <div class="block">
                    <span class="title">Business Hours</span>
                    <p>9:30am to 5:00pm</p>
                </div>
            </div>
            <div class="links reveal-section from-left staggered" use:reveal>
                <ActionButton label="Book Now" link="/book" icon="arrow-circle-right" />
            </div>
        </div>
        <!-- <div></div> -->
        <div class="hours-image reveal-section from-right staggered" use:reveal></div>
    </div>
</section>

<style>
    #visit-section {
        /* background-color: var(--color-accent-50); */
        /* border: 2px solid red; */
        /* position: relative; */
        padding: 4rem 0 6rem;
        scroll-margin-top: 2rem;
    }
    .wrapper {
        /* border: 1px solid green; */
        /* height: 42rem; */
        width: min(90%, 110rem);
        margin: 0 auto;
        /* display: flex; */
        gap: 5rem;
        display: flex;
        flex-direction: column;
    }
    @media (min-width: 60rem) {
        .wrapper {
            display: grid;
            align-items: center;
            grid-template-columns: 1fr 1fr;
        }
    }
    .hours-image {
        /* position: absolute; */
        /* border: 2px solid red; */
        /* top: 0; */
        /* left: 50%; */
        width: 100%;
        height: 35rem;
        background-image: url(/images/in-action.jpg);
        background-size: cover;
        /* background-position: center; */
        /* scale: 0.8; */
    }
    .hours {
        /* padding: 4rem 4rem 6rem 0; */
        /* padding: 4rem 0 8rem; */
        /* border: 1px solid red; */
    }
    .hours > h2 {
        color: var(--color-accent-600);
        font-size: 2.5rem;
        font-weight: 500;
        /* padding-bottom: 0.25rem; */
        /* border-bottom: 1px solid #1d1d1d; */
        display: inline-block;
        margin-bottom: 2rem;
    }
    .hours > .row {
        display: flex;
        /* align-items: flex-start; */
        align-items: center;
        gap: 1rem;
        /* border: 1px solid red; */
    }
    .hours > .row:not(:last-child) {
        padding-bottom: 1.5rem;
        margin-bottom: 1.5rem;
        border-bottom: 1px solid var(--color-accent-600);
    }
    .hours > .row > i {
        font-size: 1.5rem;
    }
    .hours > .row > .block {
        display: flex;
        align-items: center;
        justify-content: space-between;
        /* border: 1px solid red; */
        flex: 1;
        /* flex-direction: column; */
        gap: 0;
    }
    .hours > .row > .block > .title {
        opacity: 0;
        /* opacity: 0.4; */
    }
    @media (min-width: 40rem) {
        .hours > .row > .block > .title {
            opacity: 1;
            font-weight: 600;
            /* opacity: 0.4; */
        }
    }
    .hours > .row > .block > p {
        line-height: 1.25rem;
        opacity: 0.7;
        text-align: end;
    }
    .hours > .links {
        padding-top: 1rem;
        display: flex;
        align-items: center;
        justify-content: center;
        /* text-align: center; */
    }
    .book-link {
        /* background-color: var(--color-accent-500); */
        /* border-radius: 0.25rem; */
        /* color: var(--color-off-white); */
        background-color: var(--color-accent-400);
        border: 1px solid var(--color-accent-400);
        color: var(--darkest);
        font-weight: 600;
        padding: 0.75rem 2.5rem;
        transition: background-color 150ms ease;
    }
    .book-link:hover {
        background-color: var(--color-accent-500);
    }
</style>
