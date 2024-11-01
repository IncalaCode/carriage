@extends('layouts.master')

@section('title')
Dashboard
@endsection

@section('content')



<div class="row">
    <div class="col-md-12">
        <div class="card">

        </div>
        <div class="col-md-12">
            <div class="card card-plain">
                <div class="card-header">
                    <h4 class="card-title">Table on Plain Background</h4>
                    <p class="category">Here is a subtitle for this table</p>
                    <div class="float-right">
                        <form>
                            <div class="input-group no-border">
                                <!-- Input field with Bootstrap classes -->
                                <input type="text" class="form-control border-dark rounded-pill" placeholder="Search..."
                                    id="searchInput">
                                <!-- Icon placed side by side with input field -->
                                <span class="input-group-addon bg-transparent border-0">
                                    <i class="now-ui-icons ui-1_zoom-bold"></i>
                                </span>
                            </div>
                        </form>
                    </div>
                </div>
            </div>
        </div>

        <!-- Add this inline style for placeholder text color -->
        <style>
        #searchInput::placeholder {
            color: black;
            /* Black placeholder text */
        }

        /* Optional: Make input group full-width on smaller screens */
        @media (max-width: 576px) {
            .input-group {
                width: 100%;
                /* Full width for mobile devices */
            }

            .float-right {
                float: none;
                /* Remove float for better alignment on mobile */
                text-align: center;
                /* Center align on mobile */
            }
        }
        </style>



        <div class="card-body">
            <div class="table-responsive">
                <table class="table">
                    <thead class=" text-primary">
                        <th>
                            Name
                        </th>
                        <th>
                            Country
                        </th>
                        <th>
                            City
                        </th>
                        <th class="text-right">
                            Salary
                        </th>
                    </thead>
                    <tbody>
                        <tr>
                            <td>
                                Dakota Rice
                            </td>
                            <td>
                                Niger
                            </td>
                            <td>
                                Oud-Turnhout
                            </td>
                            <td class="text-right">
                                $36,738
                            </td>
                        </tr>
                        <tr>
                            <td>
                                Minerva Hooper
                            </td>
                            <td>
                                Curaçao
                            </td>
                            <td>
                                Sinaai-Waas
                            </td>
                            <td class="text-right">
                                $23,789
                            </td>
                        </tr>
                        <tr>
                            <td>
                                Sage Rodriguez
                            </td>
                            <td>
                                Netherlands
                            </td>
                            <td>
                                Baileux
                            </td>
                            <td class="text-right">
                                $56,142
                            </td>
                        </tr>
                        <tr>
                            <td>
                                Philip Chaney
                            </td>
                            <td>
                                Korea, South
                            </td>
                            <td>
                                Overland Park
                            </td>
                            <td class="text-right">
                                $38,735
                            </td>
                        </tr>
                        <tr>
                            <td>
                                Doris Greene
                            </td>
                            <td>
                                Malawi
                            </td>
                            <td>
                                Feldkirchen in Kärnten
                            </td>
                            <td class="text-right">
                                $63,542
                            </td>
                        </tr>
                        <tr>
                            <td>
                                Mason Porter
                            </td>
                            <td>
                                Chile
                            </td>
                            <td>
                                Gloucester
                            </td>
                            <td class="text-right">
                                $78,615
                            </td>
                        </tr>
                        <tr>
                            <td>
                                Jon Porter
                            </td>
                            <td>
                                Portugal
                            </td>
                            <td>
                                Gloucester
                            </td>
                            <td class="text-right">
                                $98,615
                            </td>
                        </tr>
                    </tbody>
                </table>
            </div>
        </div>
    </div>
</div>
</div>

@endsection

@section('scripts')
@endsection
<!-- Add this to your dashboard.blade.php -->


<script src="https://cdn.jsdelivr.net/npm/chart.js"></script>