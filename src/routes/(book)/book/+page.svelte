<script>
    import BookingLogin from "$lib/components/booking-form/booking-login.svelte";
    import RegisterUser from "$lib/components/booking-form/register-user.svelte";
    import Cart from "$lib/components/booking-form/cart/cart.svelte";

    // Sign-in is not wired up yet (see PRODUCT.md), so the flow starts at the cart.
    let currentPage = $state('cart');
</script>

{#if currentPage === 'email'}
    <BookingLogin onsubmit={() => currentPage = 'register'} />
{:else if currentPage === 'register'}
    <RegisterUser onsubmit={() => currentPage = 'cart'} />
{:else}
    <Cart />
{/if}
