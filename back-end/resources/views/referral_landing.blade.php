<form id="referralForm" method="POST" action="/cache-referral">
    @csrf
    <input type="hidden" name="referrer_id" value="{{ $driverId }}">
    <label for="phone">Enter Your Phone Number:</label>
    <input type="text" id="phone" name="phone" required>
    <button type="submit">Download App</button>
</form>

<script>
    document.getElementById('referralForm').addEventListener('submit', function(event) {
        event.preventDefault();

        fetch('/cache-referral', {
            method: 'POST',
            body: new FormData(this),
            headers: {
                'X-CSRF-TOKEN': document.querySelector('input[name="_token"]').value
            }
        }).then(response => response.json()).then(data => {
            if (data.redirect_url) {
                window.location.href = data.redirect_url;
            } else {
                alert(data.message);
            }
        });
    });
</script>