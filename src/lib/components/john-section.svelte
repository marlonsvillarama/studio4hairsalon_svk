<script></script>

<section>
    <div class="wrapper">
        <div class="john-img"></div>
        <div class="john-content">
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
        </div>
    </div>
</section>

<style>
    section {
        /* background-color: var(--color-accent-50); */
        /* border: 1px solid green; */
        padding: 8rem 0;
        /* height: 700px; */
        /* background-image: url(/images/pattern-001.svg); */
        /* border: 2px solid red; */
    }
    .wrapper {
        width: min(95%, 70rem);
        height: 40rem;
        margin: 0 auto;
        display: flex;
        gap: 3rem;
        align-items: flex-start;
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
        background-image: url(/images/john_3.png);
        background-size: 130%;
        background-position: 100% 50%;
        /* border: 1px solid red; */
        border-top-left-radius: 4rem;
        border-bottom-right-radius: 4rem;
        scale: 1.25rem;
        width: 30rem;
        height: 100%;
        transform: scaleX(-1);
    }
</style>