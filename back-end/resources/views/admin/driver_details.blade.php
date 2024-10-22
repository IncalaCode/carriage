<div style="margin: 20px;">
    <h1 style="color: #2c3e50; font-family: Arial, sans-serif;">Driver Details</h1>

    <div style="border: 1px solid #dcdcdc; border-radius: 10px; padding: 20px; background-color: #f9f9f9;">
        <p><strong>Name:</strong> <span style="color: #34495e;">{{ $driver->first_name }}
                {{ $driver->last_name }}</span></p>
        <p><strong>Phone Number:</strong> <span style="color: #34495e;">{{ $driver->phone_number }}</span></p>
        <p><strong>Driver ID:</strong> <span style="color: #34495e;">{{ $driver->driver_id }}</span></p>
        <p><strong>Car Type:</strong> <span style="color: #34495e;">{{ $driver->car_type }}</span></p>

        <div style="display: flex; flex-wrap: wrap; gap: 20px;">
            <div style="flex: 1; min-width: 200px; max-width: 300px;">
                <strong>ID Card:</strong>
                <img src="{{ asset('storage/' . $driver->id_card_image_path) }}" alt="ID Card"
                    style="width: 100%; border-radius: 5px; box-shadow: 0 2px 4px rgba(0,0,0,0.1);">
            </div>
            <div style="flex: 1; min-width: 200px; max-width: 300px;">
                <strong>Driver License:</strong>
                <img src="{{ asset('storage/' . $driver->driver_license_photo) }}" alt="Driver License"
                    style="width: 100%; border-radius: 5px; box-shadow: 0 2px 4px rgba(0,0,0,0.1);">
            </div>
            <div style="flex: 1; min-width: 200px; max-width: 300px;">
                <strong>Car Plate:</strong>
                <img src="{{ asset('storage/' . $driver->car_plate_photo) }}" alt="Car Plate"
                    style="width: 100%; border-radius: 5px; box-shadow: 0 2px 4px rgba(0,0,0,0.1);">
            </div>
            <div style="flex: 1; min-width: 200px; max-width: 300px;">
                <strong>User Photo:</strong>
                <img src="{{ asset('storage/' . $driver->user_photo) }}" alt="User Photo"
                    style="width: 100%; border-radius: 5px; box-shadow: 0 2px 4px rgba(0,0,0,0.1);">
            </div>
        </div>

        <div style="margin-left: 80%; margin-top:60px;">
            <form action="{{ route('admin.approve_driver', $driver->id) }}" method="POST" style="display:inline;">
                @csrf
                @method('PUT')
                <button type="submit"
                    style="background-color: green; color: white; border: none; padding: 10px 20px; border-radius: 5px; font-size: 20px;">Approve</button>
            </form>
        </div>
    </div>
</div>