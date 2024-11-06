<?php

namespace App\Models;

class RequestStatus
{
    // Client request statuses
    const PENDING = 'pending';
    const DRIVER_ACCEPTED = 'driver_accepted';
    const LOCKED = 'locked';
    const IN_PROGRESS = 'in_progress';
    const COMPLETED = 'completed';
    const CANCELLED = 'cancelled';

    // Next possible actions based on current status
    public static function getNextActions($currentStatus)
    {
        return [
            self::PENDING => ['get_drivers', 'cancel_request'],
            self::DRIVER_ACCEPTED => ['select_driver', 'cancel_request'],
            self::LOCKED => ['track_driver', 'complete_ride'],
            self::IN_PROGRESS => ['track_driver', 'complete_ride'],
            self::COMPLETED => ['create_request'],
            self::CANCELLED => ['create_request'],
        ];
    }
} 