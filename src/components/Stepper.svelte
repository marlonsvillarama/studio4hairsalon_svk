<script>
    import { createStringHelper } from "$lib/data/strings.svelte";

    const stringHelper = createStringHelper();
    
    let {
        id = stringHelper.getRandomId(),
        step = 1
    } = $props();

    $effect(() => {
        let stepper = document.getElementById(id);
        let allSteps = stepper?.querySelectorAll('.step');
        allSteps?.forEach(step => {
            step.classList.remove('active');
        });

        let activeStep = stepper?.querySelector(`[data-step="${step.toString()}"]`);
        if (activeStep) {
            activeStep.classList.add('active');
        }
    });
</script>

<div class="stepper" {id}>
    <div class="step active" data-step="1">
        <span class="number">1</span>
        <span class="help">Choose the service</span>
        <span class="help-short">Service</span>
    </div>
    <div class="step" data-step="2">
        <span class="number">2</span>
        <span class="help">Share your details</span>
        <span class="help-short">Details</span>
    </div>
    <div class="step" data-step="3">
        <span class="number">3</span>
        <span class="help">Confirm your appointment</span>
        <span class="help-short">Confirm</span>
    </div>
</div>

<style>
    .stepper {
        /* border: 1px solid red; */
        width: 100%;
        display: grid;
        grid-template-columns: repeat(3, 1fr);
        gap: 0.25rem;
    }
    .step {
        padding: 0.75rem 1.5rem;
        border: 0;
        border-bottom: 4px solid var(--color-border-lite);
        color: var(--color-grey-dark-03-rgb-lite);
        text-align: center;
        display: flex;
        flex-direction: column;
        justify-content: center;
        align-items: center;
        gap: 0.5rem;
        cursor: pointer;
        transition: all 150ms ease-in-out;
    }
    .number {
        /* color: var(--color-grey-dark-03-rgb-lite); */
        font-family: var(--font-serif);
        font-size: var(--fs-xl);
        font-weight: 400;
        border: 1px solid var(--color-grey-dark-03-rgb-lite);
        padding: 7px 12px;
        border-radius: 50%;
    }
    @media (min-width: 40rem) {
        .number {
            font-size: var(--fs-2xl);
            padding: 13px 16px;
            border-radius: 50%;
        }
    }

    .help {
        display: none;
        font-size: var(--fs-sm);
    }
    .help-short {
        display: block;
        font-size: var(--fs-sm);
        font-weight: 200;
    }
    @media (min-width: 40rem) and (width < 64rem) {
        .help-short {
            display: block;
        }
    }
    @media (min-width: 64rem) {
        .help {
            display: block;
            font-weight: 200;
        }
        .help-short {
            display: none;
        }
    }

    .step.active {
        border-bottom: 4px solid var(--color-accent);
    }
    .step.active > .number {
        border: 1px solid var(--color-accent);
        color: var(--color-accent);
    }
    .step.active > .help,
    .step.active > .help-short {
        font-weight: 500;
    }
    .step:not(.active):hover {
        border-bottom: 4px solid var(--color-border);
    }
    .step:not(.active):hover > .help{
        font-weight: 300;
    }
</style>