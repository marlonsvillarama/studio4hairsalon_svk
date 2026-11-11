<script>
    import { reveal } from "$lib/reveal";
    import { scrollTo } from "$lib/scroll";
    import ActionButton from "./shared/action-button.svelte";
</script>

<section id="john-section">
    <div class="wrapper">
        <div class="header reveal-section from-bottom staggered" use:reveal>
            <h2>John Fernandez</h2>
            <p>
                A seasoned professional with over 20 years of international experience, John brings world-class expertise and creativity to every client.
            </p>
            <p>
                John's journey spans the vibrant salons of Dubai, the dynamic multi-franchise networks of the Philippines, and the innovative hair industry of New Zealand.
            </p>
            <p>
                His extensive background combines diverse techniques, global trends, and a passion for excellence to ensure you receive a look tailored specifically to your unique style.
            </p>
            <ActionButton label="Read Reviews" icon="arrow-down"
                onclick={() => scrollTo('reviews-section')}
            />
        </div>
        <div class="john-img reveal-section from-bottom staggered" use:reveal></div>
        <!-- <div class="john-content">
            <div class="john">John</div>
            <div class="fernandez">Fernandez</div>
            <p>
                A seasoned professional with over 20 years of international experience, John brings world-class expertise and creativity to every client.
            </p>
            <p>
                John's journey spans the vibrant salons of Dubai, the dynamic multi-franchise networks of the Philippines, and the innovative hair industry of New Zealand.
            </p>
            <p>
                His extensive background combines diverse techniques, global trends, and a passion for excellence to ensure you receive a look tailored specifically to your unique style.
            </p>
        </div> -->
    </div>
</section>

<style>
    #john-section {
        /* background-color: var(--color-accent-50); */
        /* border: 1px solid green; */
        padding: 4rem 0 6rem;
        scroll-margin-top: 2em;
        /* height: 700px; */
        /* background-image: url(/images/pattern-001.svg); */
        /* border: 2px solid red; */
    }
    .wrapper {
        /* border: 1px solid red; */
        width: min(90%, 60rem);
        /* height: 30rem; */
        margin: 0 auto;
        display: flex;
        flex-direction: column;
        align-items: center;
        gap: 3rem;
    }
    .wrapper > .header {
        display: flex;
        flex-direction: column;
        justify-content: flex-start;
        gap: 0.5rem;
        margin: 0 auto;
        width: min(40rem, 100%);
    }
    .wrapper > .header > h2 {
        text-align: center;
        font: 600 2.5rem var(--font-serif);
    }
    .wrapper > .header > p {
        /* border: 1px solid red; */
        /* letter-spacing: 0.25px; */
        line-height: 1.75rem;
        margin: 0.5rem auto;
        opacity: 0.8;
        width: min(100%, 40rem);
    }

    .john-content {
        /* border: 1px solid red; */
        /* background-color: var(--color-accent-100); */
        flex: 1;
        display: flex;
        flex-direction: column;
        /* align-items: flex-end; */
        justify-content: flex-end;
        gap: 1.5rem;
        /* justify-content: end; */
        position: relative;
        height: 100%;
    }
    .john-content > p {
        opacity: 0.6;
        letter-spacing: -0.25px;
        line-height: 1.75rem;
        /* font-weight: 300; */
    }
    .john,
    .fernandez {
        position: absolute;
        font-size: 9rem;
        font-weight: 500;
        letter-spacing: -3px;
        line-height: 5rem;
    }
    .john {
        top: 4rem;
        left: -7.5rem;
    }
    .fernandez {
        top: 12rem;
        left: -7.5rem;
    }
    .wrapper > .john-img {
        background-image: url(/images/john.avif);
        background-size: cover;
        /* background-position: center center; */
        /* background-size: 130%; */
        background-position: 100% center;
        /* border: 1px solid red; */
        border-top-left-radius: 4rem;
        border-bottom-right-radius: 4rem;
        /* scale: 1.25rem; */
        width: min(25rem, 100%);
        height: 35rem;
        transform: scaleX(-1);
    }
    @media (min-width: 60rem) {
        .wrapper {
            /* height: 40rem; */
            flex-direction: row;
            width: min(90%, 60rem);
        }
        .wrapper > .john-img {
            order: 1;
        }
        .wrapper > .header {
            order: 2;
        }
        .wrapper > .header > h2 {
            text-align: start;
            font: 600 3.5rem var(--font-serif);
        }
    }
</style>