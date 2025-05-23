<script>
    import CalendarIcon from '$lib/images/icons/calendar.svg';
    import ClockIcon from '$lib/images/icons/clock.svg';
    import EmailIcon from '$lib/images/icons/email.svg';
    import HouseIcon from '$lib/images/icons/house.svg';
    import MobilePhoneIcon from '$lib/images/icons/mobilephone.svg';
    import PhoneIcon from '$lib/images/icons/phone.svg';
    const KEY = 'AIzaSyAkzcOGc8ScKj-12XHFU90hKGfTw1-MaP4';
    const URL = `https://www.google.com/maps/embed/v1/place?key=${KEY}&q=Studio+4+Hair+Salon&center=-40.3556086,175.6071483&zoom=16`;
</script>

<section class="wrapper">
    <div class="child hours">
        <h3>Salon Hours</h3>

        <div class="row">
            <img src={CalendarIcon} alt="Days open">
            <p><span class="day">Monday</span> to <span class="day">Saturday</span></p>
        </div>

        <div class="row">
            <img src={ClockIcon} alt="Hours open">
            <p><span class="time">9:30 am</span> to <span class="time">5:00 pm</span></p>
        </div>
    </div>

    <div class="separator"></div>

    <div class="child contact">
        <h3>Contact Info</h3>

        <div class="row">
            <img src={HouseIcon} alt="Address">
            <p class="address"><span>7 George Street</span><span>Palmerston North</span></p>
        </div>

        <div class="row">
            <img src={PhoneIcon} alt="Phone">
            <p>(06) 353-5678</p>
        </div>

        <div class="row">
            <img src={MobilePhoneIcon} alt="Mobile phone">
            <p>(022) 188-5240</p>
        </div>
    </div>
</section>

<!-- <section class="wrapper">
    <div class="map">
        <iframe title="Studio4 Hair Salon" src={URL} frameborder="0"></iframe>
    </div>
</section> -->

<style>
    section {
        /* border: 1px solid red; */
        /* padding-top: 3rem; */
        /* padding-bottom: 3rem; */
        /* border: 0px solid red; */
        display: flex;
        flex-direction: column;
        /* grid-template-columns: calc(60% - 3rem) 40%; */
        /* align-items: center; */
        /* justify-content: center; */
        gap: 3rem;
        /* border-collapse: collapse; */
    }
    @media (min-width: 40rem) {
        section {
            /* width: 5%; */
            display: grid;
            /* flex-direction: row; */
            gap: 3rem;
            grid-template-columns: 1fr 1px 1fr;
            /* gap: 4rem; */
            align-items: flex-start;
            /* justify-content: center; */
        }
        /* section > .hours {
            grid-area: "hours";
        }
        section > .contact {
            grid-area: "contact";
        } */
        /* section > .map {
            grid-area: "map";
        } */
    }

    section > .child {
        /* border: 1px solid green; */
        /* border-collapse: collapse; */
        /* height: 100px; */
        /* text-align: center; */
        width: 100%;
        margin: 0 auto;
        display: flex;
        flex-direction: column;
        /* align-items: center; */
    }

    .separator {
        display: none;
        background-color: var(--color-accent);
        height: 1px;
        width: 100%;
        /* margin: 0 auto; */
    }
    @media (min-width: 40rem) {
        .separator {
            height: 100%;
            display: block;
            /* margin: auto 0; */
        }
    }

    h3 {
        font-family: var(--font-serif);
        font-optical-sizing: auto;
        font-size: var(--fs-xl);
        font-weight: 700;
        color: var(--color-accent);
        letter-spacing: 0.25px;
        /* text-shadow: 1px 1px 1px rgba(0, 0, 0, 0.4); */
        padding-bottom: 1rem;
        margin-bottom: 1rem;
        border-bottom: 1px dotted var(--color-border);
        /* border: 1px solid red; */
    }
    @media (min-width: 64rem) {
        h3 {
            font-size: var(--fs-2xl);
            /* margin-bottom: 2rem; */
        }
    }

    .row {
        display: flex;
        flex-direction: row;
        align-items: flex-start;
        gap: 2rem;
        color: var(--color-grey-dark-03-rgb);
        font-size: var(--fs-sm);
        font-weight: 300;
    }
    .row:not(:last-child) {
        margin-bottom: 1rem;
    }
    .row img {
        height: 1.5rem;
    }
    .row > .address {
        display: flex;
        flex-direction: column;
        gap: 0.25rem;
    }
    /* .hours, .contact { */
        /* gap: 1.5rem; */
        /* text-align: center; */
        /* border-bottom: 1px solid red; */
    /* } */
    .hours > p {
        /* width: 75%; */
        /* border: 1px solid red; */
        color: var(--color-grey-dark-03-rgb);
        font-size: var(--fs-sm);
        font-weight: 100;
        letter-spacing: 0.25px;
        display: flex;
        flex-direction: row;
        gap: 0.5rem;
        /* align-items: baseline; */
    }
    .hours > p:not(:last-child) {
        margin-bottom: 0.5rem;
    }
    @media (min-width: 64rem) {
        .hours > p {
            gap: 1rem;
            margin-bottom: 1rem;
        }
    }
    .hours > p > span.day,
    .hours > p > span.time {
        font-size: var(--fs-lg);
        font-weight: 500;
    }
    @media (min-width: 64rem) {
        .hours > p > span.day,
        .hours > p > span.time {
            font-size: var(--fs-xl);
            font-weight: 600;
        }
    }

    /* .contact > div {
        display: flex;
        flex-direction: column;
        gap: 1rem;
        /* justify-content: center; *!/
        align-items: center;
        width: 100%;
        border: 0px solid red;
    } */
    /* .contact p {
        font-size: var(--fs-lg);
    }
    @media (min-width: 64rem) {
        .contact p {
            font-size: var(--fs-xl);
        }
    } */
    /* .contact > div > .address {
        display: flex;
        flex-direction: column;
        align-items: center;
    } */
    /* .contact > div > .address > span:first-child {
        font-size: var(--fs-xl);
        font-weight: 600;
        color: var(--color-grey-dark-03-rgb);
        margin-bottom: 1.5rem;
    } */
    /* .contact > div > .address > span:last-child {
        font-size: var(--fs-xl);
        font-weight: 300;
        color: var(--color-grey-dark-03-rgb);
        margin-bottom: 1rem;
    } */
    /* .contact > div > .phone {
        display: flex;
        flex-direction: row;
        justify-content: space-between;
        align-items: center;
        width: 100%;
        /* border: 1px solid red; *!/
        color: var(--color-grey-dark-03-rgb);
        margin-bottom: 0.5rem;
    } */
    /* .contact > div > .phone > span:first-child {
        font-weight: 100;
        font-size: var(--fs-lg);
        color: var(--color-grey-dark-03-rgb);
    } */
    /* .contact > div > .phone > span:last-child {
        font-size: var(--fs-xl);
        font-weight: 500;
        /* color: var(--color-grey-dark-03-rgb); *!/
        color: var(--color-accent);
        /* margin-bottom: 1rem; *!/
    } */
    /* .phone > span {
        font-size: var(--fs-lg);
        font-weight: 500;
        color: var(--color-grey-dark-03-rgb);
    } */
    /* .map {
        width: 100%;
        height: 100%;
    } */
    /* iframe {
        border: 0;
        width: 100%;
        height: 100%;
    } */
</style>