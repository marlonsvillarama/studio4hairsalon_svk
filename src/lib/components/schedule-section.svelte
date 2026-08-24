<section>
    <div class="wrapper">
        <div class="hours">
            <h2>Booking</h2>
        </div>
        <div></div>
    </div>
    <div class="hours-image"></div>
</section>

<style>
    section {
        background-color: var(--color-accent-50);
        /* border: 2px solid red; */
        position: relative;
    }
    .wrapper {
        /* border: 1px solid green; */
        height: 40rem;
        width: min(95%, 70rem);
        margin: 0 auto;
        /* display: flex; */
        /* gap: 3rem; */
        /* align-items: flex-start; */
        display: grid;
        grid-template-columns: 1fr 1fr;
    }
    .hours-image {
        position: absolute;
        /* border: 2px solid red; */
        top: 0;
        left: 50%;
        width: 50%;
        height: 40rem;
        background-image: url(/images/in-action.jpg);
        background-size: cover;
        background-position: center 0;
        /* scale: 0.8; */
    }
    .hours {
        padding: 4rem 0 8rem;
    }
    .hours > h2 {
        font-size: 2.5rem;
        /* font-weight: 200; */
    }
</style>
