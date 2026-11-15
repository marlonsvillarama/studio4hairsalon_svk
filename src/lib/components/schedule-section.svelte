<script>
    import { reveal } from "$lib/reveal";
  import ActionButton from "./shared/action-button.svelte";
</script>

<section id="visit-section" aria-labelledby="visit-heading">
    <div class="wrapper">
        <div class="hours reveal-section from-left" use:reveal>
            <h2 id="visit-heading">Come and see me</h2>
            <dl>
            <div class="row reveal-section from-left staggered" use:reveal>
                <i class="ph ph-map-pin" aria-hidden="true"></i>
                <dt class="title">Location</dt>
                <dd>7 George Street<br />Palmerston North</dd>
            </div>
            <div class="row reveal-section from-left staggered" use:reveal>
                <i class="ph ph-phone" aria-hidden="true"></i>
                <dt class="title">Phone</dt>
                <dd><a href="tel:+6463535678">(06) 353-5678</a></dd>
            </div>
            <div class="row reveal-section from-left staggered" use:reveal>
                <i class="ph ph-device-mobile" aria-hidden="true"></i>
                <dt class="title">Mobile</dt>
                <dd><a href="tel:+64221885240">(022) 188-5240</a></dd>
            </div>
            <div class="row reveal-section from-left staggered" use:reveal>
                <i class="ph ph-calendar-dots" aria-hidden="true"></i>
                <dt class="title">Days open</dt>
                <dd>Mondays to Saturdays</dd>
            </div>
            <div class="row reveal-section from-left staggered" use:reveal>
                <i class="ph ph-clock" aria-hidden="true"></i>
                <dt class="title">Hours</dt>
                <dd>9:30am to 5:00pm</dd>
            </div>
            </dl>
            <div class="links reveal-section from-left staggered" use:reveal>
                <ActionButton label="Book with John" link="/book" icon="arrow-right" />
            </div>
        </div>
        <div class="hours-image reveal-section from-right staggered" use:reveal
            role="img" aria-label="John styling a client's hair in the salon"></div>
    </div>
</section>

<style>
    #visit-section {
        padding: 4rem 0 6rem;
        scroll-margin-top: 2rem;
    }
    .wrapper {
        width: min(90%, 110rem);
        margin: 0 auto;
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
        width: 100%;
        height: 35rem;
        background-image: url(/images/in-action.jpg);
        background-size: cover;
    }
    .hours > h2 {
        color: var(--darkest);
        font: 700 clamp(2rem, 5vw, 2.75rem) / 1.15 var(--font-serif);
        display: inline-block;
        margin-bottom: 2rem;
    }
    .hours > dl > .row {
        display: flex;
        align-items: center;
        gap: 1rem;
    }
    .hours > dl > .row:not(:last-child) {
        padding-bottom: 1.5rem;
        margin-bottom: 1.5rem;
        border-bottom: 1px solid var(--color-accent-300);
    }
    .hours > dl > .row > i {
        font-size: 1.5rem;
    }
    .hours > dl > .row > .title {
        flex: 1;
    }
    .hours > dl > .row > .title {
        color: var(--darkest);
        font-weight: 600;
    }
    .hours > dl > .row > dd {
        color: var(--charcoal);
        line-height: 1.4;
        text-align: end;
    }
    .hours > dl > .row > dd > a {
        color: var(--darkest);
        font-weight: 600;
        text-decoration: underline;
        text-decoration-color: var(--color-accent-600);
        text-underline-offset: 4px;
        display: inline-block;
        padding: 0.5rem 0;
        margin: -0.5rem 0;
    }
    .hours > dl > .row > i {
        color: var(--color-accent-700);
    }
    .hours > .links {
        padding-top: 1rem;
        display: flex;
        align-items: center;
        justify-content: center;
    }
</style>
