<script>
    const KEY = 'AIzaSyAkzcOGc8ScKj-12XHFU90hKGfTw1-MaP4';
    const URL = `https://www.google.com/maps/embed/v1/place?key=${KEY}&q=Studio+4+Hair+Salon&center=-40.3556086,175.6071483&zoom=16`;
</script>

<section class="wrapper">
    <div class="hours">
        <span class="title">Salon Hours</span>
        <p><span class="day">Monday</span> to <span class="day">Saturday</span></p>
        <p><span class="time">9:30 am</span> to <span class="time">5:00 pm</span></p>
    </div>

    <div class="separator"></div>

    <div class="contact">
        <span class="title">Contact Info</span>
        <div>
            <p class="address"><span>7 George Street</span><span>Palmerston North</span></p>
            <p class="phone"><span>Phone</span><span>(06) 353-5678</span></p>
            <p class="phone"><span>Mobile</span><span>(022) 188-5240</span></p>
        </div>
    </div>

    <div class="separator"></div>

    <div class="map">
        <iframe title="Studio4 Hair Salon" src={URL} frameborder="0"></iframe>
    </div>
</section>

<style>
    section {
        /* border: 1px solid red; */
        /* padding-top: 3rem; */
        /* padding-bottom: 3rem; */
        /* border: 0px solid red; */
        display: flex;
        flex-direction: column;
        /* grid-template-columns: calc(60% - 3rem) 40%; */
        align-items: center;
        justify-content: center;
        gap: 2rem;
        /* border-collapse: collapse; */
    }
    @media (min-width: 64rem) {
        section {
            /* width: 100%; */
            display: grid;
            grid-template-columns: 1fr 1px 1fr 1px 1fr;
            /* gap: 4rem; */
            align-items: flex-start;
            /* justify-content: center; */
        }
    }

    section > div {
        /* border: 0px solid red; */
        /* border-collapse: collapse; */
        /* height: 100px; */
        /* text-align: center; */
        width: 100%;
        margin: 0 auto;
        display: flex;
        flex-direction: column;
        align-items: center;
    }

    .separator {
        background-color: var(--color-accent);
        height: 1px;
        width: 100%;
    }
    @media (min-width: 64rem) {
        .separator {
            height: 100%;
        }
    }

    .title {
        font-family: var(--font-serif);
        font-optical-sizing: auto;
        font-size: var(--fs-2xl);
        font-weight: 700;
        color: var(--color-accent);
        letter-spacing: 0.25px;
        /* text-shadow: 1px 1px 1px rgba(0, 0, 0, 0.4); */
        padding-bottom: 1rem;
        border-bottom: 1px dotted var(--color-border);
        margin-bottom: 1rem;
        /* border: 1px solid red; */
    }
    .hours, .contact {
        gap: 1.5rem;
        /* text-align: center; */
        /* border-bottom: 1px solid red; */
    }
    .hours > p {
        /* width: 75%; */
        /* border: 1px solid red; */
        color: var(--color-grey-dark-03-rgb);
        font-size: var(--fs-lg);
        font-weight: 100;
        display: flex;
        flex-direction: row;
        gap: 1rem;
        align-items: baseline;
    }
    .hours > p > span.day {
        font-size: var(--fs-xl);
        font-weight: 600;
    }
    .hours > p > span.time {
        font-size: var(--fs-xl);
        font-weight: 500;
    }

    .contact > div {
        display: flex;
        flex-direction: column;
        gap: 1rem;
        /* justify-content: center; */
        align-items: center;
        width: 80%;
        border: 0px solid red;
    }
    .contact > div > .address {
        display: flex;
        flex-direction: column;
        align-items: center;
    }
    .contact > div > .address > span:first-child {
        font-size: var(--fs-xl);
        font-weight: 600;
        color: var(--color-grey-dark-03-rgb);
        margin-bottom: 1.5rem;
    }
    .contact > div > .address > span:last-child {
        font-size: var(--fs-xl);
        font-weight: 300;
        color: var(--color-grey-dark-03-rgb);
        margin-bottom: 1rem;
    }
    .contact > div > .phone {
        display: flex;
        flex-direction: row;
        justify-content: space-between;
        align-items: center;
        width: 100%;
        /* border: 1px solid red; */
        color: var(--color-grey-dark-03-rgb);
        margin-bottom: 0.5rem;
    }
    .contact > div > .phone > span:first-child {
        font-weight: 100;
        font-size: var(--fs-lg);
        color: var(--color-grey-dark-03-rgb);
    }
    .contact > div > .phone > span:last-child {
        font-size: var(--fs-xl);
        font-weight: 500;
        /* color: var(--color-grey-dark-03-rgb); */
        color: var(--color-accent);
        /* margin-bottom: 1rem; */
    }
    .map {
        width: 80%;
        height: 100%;
    }
    iframe {
        border: 0;
        width: 100%;
        height: 100%;
    }

</style>