<section>
    <div class="wrapper">
        <div class="header">
            <span>Our Services</span>
            <h2>What We Offer</h2>
        </div>
        <div class="cards">
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
    </div>
</section>

<style>
    section {
        /* border: 1px solid green; */
        padding: 4rem 0 8rem;
        /* height: 40rem; */
        background-color: var(--color-accent-50);
        /* background-image: url(/images/pattern-001.svg); */
        /* border: 2px solid red; */
    }
    .wrapper {
        width: min(95%, 110rem);
        margin: 0 auto;
        display: flex;
        flex-direction: column;
        gap: 2rem;
    }
    .wrapper > .header > span {
        font-size: 0.875rem;
        /* font-weight: 300; */
        opacity: 0.6;
        text-transform: uppercase;
    }
    .wrapper > .header > h2 {
        font-size: 3.5rem;
        /* font-family: var; */
        line-height: 3.5rem;
    }
    .wrapper > .cards {
        display: grid;
        grid-template-columns: repeat(4, 1fr);
        gap: 0.25rem;
    }
    .wrapper > .cards > .card {
        /* border: 1px solid red; */
        height: 35rem;
        background-size: cover;
        /* background-size: 80%; */
        background-position: 70%;
        cursor: pointer;
        display: flex;
        flex-direction: column;
        justify-content: flex-end;
        text-align: center;
        transition:
            box-shadow 150ms ease,
            height 150ms ease,
            width 150ms ease,
            transform 150ms ease,
            z-index 150ms ease,
            background-image 150ms ease;
    }
    /* .wrapper > .cards > .card:hover { */
        /* box-shadow: rgba(50, 50, 93, 0.25) 0px 13px 27px -5px, rgba(0, 0, 0, 0.3) 0px 8px 16px -8px; */
        /* box-shadow: rgba(0, 0, 0, 0.35) 0px 5px 15px; */
        /* box-shadow: var(--color-accent-200) 0px 5px 15px; */
        /* transform: scale(1.02); */
        /* z-index: 999; */
    /* } */
    .wrapper > .cards > .card > .title {
        margin-bottom: 2rem;
        color: var(--color-off-white);
        font-family: var(--font-serif);
        font-size: 2.25rem;
        font-weight: 300;
        letter-spacing: 0.5px;
    }
    .haircut {
        background-image:
            linear-gradient(to bottom, rgba(0, 0, 0, 0) 0%, rgba(0, 0, 0, 0.5) 90%),
            url(/images/haircut.jpg);
    }
    .haircut:hover {
        background-image:
            linear-gradient(to bottom, rgba(0, 0, 0, 0) 50%, rgba(0, 0, 0, 0.5) 90%),
            url(/images/haircut.jpg);
    }
    .colours {
        background-image:
            linear-gradient(to bottom, rgba(0, 0, 0, 0) 0%, rgba(0, 0, 0, 0.5) 90%),
            url(/images/colour.jpg);
        background-position: 65% !important;
    }
    .colours:hover {
        background-image:
            linear-gradient(to bottom, rgba(0, 0, 0, 0) 60%, rgba(0, 0, 0, 0.5) 90%),
            url(/images/colour.jpg);
        background-position: 65% !important;
    }
    .keratin {
        background-image:
            linear-gradient(to bottom, rgba(0, 0, 0, 0) 0%, rgba(0, 0, 0, 0.5) 90%),
            url(/images/treatment.jpg);
        background-position: 70% !important;
    }
    .keratin:hover {
        background-image:
            linear-gradient(to bottom, rgba(0, 0, 0, 0) 60%, rgba(0, 0, 0, 0.5) 90%),
            url(/images/treatment.jpg);
        background-position: 70% !important;
    }
    .other {
        background-image:
            linear-gradient(to bottom, rgba(0, 0, 0, 0) 0%, rgba(0, 0, 0, 0.5) 90%),
            url(/images/makeup.jpg);
    }
    .other:hover {
        background-image:
            linear-gradient(to bottom, rgba(0, 0, 0, 0) 60%, rgba(0, 0, 0, 0.5) 90%),
            url(/images/makeup.jpg);
    }
</style>