<section>
    <div class="wrapper">
        <div class="hours">
            <h2>Visit Us</h2>
            <div class="row">
                <i class="ph-thin ph-map-pin"></i>
                <div class="block">
                    <span class="title">Location</span>
                    <p>7 George Street<br/>Palmerston North</p>
                </div>
            </div>
            <div class="row">
                <i class="ph-thin ph-phone"></i>
                <div class="block">
                    <span class="title">Phone Number</span>
                    <p>(06) 353-5678</p>
                </div>
            </div>
            <div class="row">
                <i class="ph-thin ph-device-mobile"></i>
                <div class="block">
                    <span class="title">Mobile Number</span>
                    <p>(022) 188-5240</p>
                </div>
            </div>
            <div class="row">
                <i class="ph-thin ph-calendar-dots"></i>
                <div class="block">
                    <span class="title">Days Open</span>
                    <p>Mondays to Saturdays</p>
                </div>
            </div>
            <div class="row">
                <i class="ph-thin ph-clock"></i>
                <div class="block">
                    <span class="title">Business Hours</span>
                    <p>9:30am to 5:00pm</p>
                </div>
            </div>
            <div class="links">
                <a href="#" class="book-link" title="Book Now">Book Now</a>
            </div>
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
        height: 42rem;
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
        height: 42rem;
        background-image: url(/images/in-action.jpg);
        background-size: cover;
        background-position: center 0;
        /* scale: 0.8; */
    }
    .hours {
        padding: 4rem 4rem 8rem 0;
        /* padding: 4rem 0 8rem; */
        /* border: 1px solid red; */
    }
    .hours > h2 {
        color: var(--color-amber-600);
        font-size: 2.5rem;
        font-weight: 300;
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
        font-size: 2rem;
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
        font-weight: 600;
        /* opacity: 0.4; */
    }
    .hours > .row > .block > p {
        line-height: 1.25rem;
        opacity: 0.7;
        text-align: end;
    }
    .hours > .links {
        padding-top: 1.5rem;
    }
    .book-link {
        background-color: var(--color-accent-500);
        /* border-radius: 0.25rem; */
        color: var(--color-off-white);
        padding: 0.75rem 2.5rem;
        transition: background-color 150ms ease;
    }
    .book-link:hover {
        background-color: var(--color-accent-600);
    }
</style>
