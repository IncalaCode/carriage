 <!DOCTYPE html>
 <html lang="en">

 <head>
     <meta charset="utf-8" />
     <link rel="apple-touch-icon" sizes="76x76" href="../assets/img/apple-icon.png">
     <link rel="icon" type="image/png" href="../assets/img/favicon.png">
     <meta http-equiv="X-UA-Compatible" content="IE=edge,chrome=1" />
     <title> @yield('title')</title>
     <meta content='width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=0, shrink-to-fit=no'
         name='viewport' />
     <!--     Fonts and icons     -->
     <link href="https://fonts.googleapis.com/css?family=Montserrat:400,700,200" rel="stylesheet" />
     <link href="https://use.fontawesome.com/releases/v5.0.6/css/all.css" rel="stylesheet">
     <!-- CSS Files -->
     <link href="../assets/css/bootstrap.min.css" rel="stylesheet" />
     <link href="../assets/css/now-ui-dashboard.css?v=1.0.0" rel="stylesheet" />
     <!-- CSS Just for demo purpose, don't include it in your project -->
     <link href="../assets/demo/demo.css" rel="stylesheet" />
     <style>
     .notification-dot {
         position: absolute;
         top: 5px;
         right: 10px;
         width: 8px;
         height: 8px;
         background-color: red;
         border-radius: 50%;
     }
     </style>

 </head>

 <body class="">
     <div class="wrapper ">
         <div class="sidebar" data-color="orange">
             <!--
        Tip 1: You can change the color of the sidebar using: data-color="blue | green | orange | red | yellow"
    -->
             <div class="logo">
                 <a href="http://www.creative-tim.com" class="simple-text logo-mini">
                     MT
                 </a>
                 <a href="http://www.creative-tim.com" class="simple-text logo-normal">
                     My Truck
                 </a>
             </div>
             <div class="sidebar-wrapper">
                 <ul class="nav">
                     <li>
                         <a href="{{ route('admin.dashboard') }}">
                             <i class="now-ui-icons design_app"></i>
                             <p>Dashboard</p>
                         </a>
                     </li>
                     <li>
                         <a href="{{ route('admin.drivers') }}">
                             <i class="now-ui-icons users_single-02"></i>
                             <p>Drivers</p>
                         </a>
                     </li>
                     <li>
                         <a href="{{ route('admin.users') }}">
                             <i class="now-ui-icons users_single-02"></i>
                             <p>Users</p>
                         </a>
                     </li>

                     <li>
                         <a href="{{ route('admin.unapproved_drivers') }}" class="nav-link">
                             <i class="now-ui-icons users_single-02"></i>
                             <p>approval</p>
                         </a>
                     </li>
                     <li>
                         <a href="">
                             <i class="now-ui-icons shopping_box"></i>
                             <p>Orders</p>
                         </a>
                     </li>
                     <li>
                         <a href="{{ route('admin.settings') }}">
                             <i class="now-ui-icons ui-1_settings-gear-63"></i>
                             <p>settings</p>
                         </a>
                     </li>
                 </ul>
             </div>
         </div>
         <div class="main-panel">
             <!-- Navbar -->
             <nav class="navbar navbar-expand-lg navbar-transparent  navbar-absolute bg-primary fixed-top">
                 <div class=" container-fluid ">
                     <div class=" navbar-wrapper">
                         <div class="navbar-toggle">
                             <button type="button" class="navbar-toggler">
                                 <span class="navbar-toggler-bar bar1"></span>
                                 <span class="navbar-toggler-bar bar2"></span>
                                 <span class="navbar-toggler-bar bar3"></span>
                             </button>
                         </div>
                         <a class="navbar-brand" href="#pablo">My Truck </a>
                     </div>
                     <button class="navbar-toggler" type="button" data-toggle="collapse" data-target="#navigation"
                         aria-controls="navigation-index" aria-expanded="false" aria-label="Toggle navigation">
                         <span class="navbar-toggler-bar navbar-kebab"></span>
                         <span class="navbar-toggler-bar navbar-kebab"></span>
                         <span class="navbar-toggler-bar navbar-kebab"></span>
                     </button>
                     <div class="collapse navbar-collapse justify-content-end" id="navigation">

                         <ul class="navbar-nav">
                             <!-- <li class="nav-item">
                                 <a class="nav-link" href="#pablo">
                                     <i class="now-ui-icons media-2_sound-wave"></i>
                                     <p>
                                         <span class="d-lg-none d-md-block">Stats</span>
                                     </p>
                                 </a>
                             </li> -->
                             <li class="nav-item dropdown">
                                 <a class="nav-link dropdown-toggle" href="#" id="navbarDropdownMenuLink"
                                     data-toggle="dropdown" aria-haspopup="true" aria-expanded="false">
                                     <i class="now-ui-icons ui-1_email-85"></i>
                                     @if($unapprovedDriversCount > 0)
                                     <span class="badge badge-danger">{{ $unapprovedDriversCount }}</span>
                                     @endif
                                 </a>
                                 <div class="dropdown-menu dropdown-menu-right"
                                     aria-labelledby="navbarDropdownMenuLink">
                                     <a class="dropdown-item" href="{{ route('admin.unapproved_drivers') }}">Unapproved
                                         Drivers: {{ $unapprovedDriversCount }}</a>
                                 </div>
                             </li>


                             <li class="nav-item">
                                 <a class="nav-link" href="#pablo">
                                     <i class="now-ui-icons users_single-02"></i>
                                     <p>
                                         <span class="d-lg-none d-md-block">Account</span>
                                     </p>
                                 </a>
                             </li>
                         </ul>
                     </div>
                 </div>
             </nav>
             <!-- End Navbar -->

             <div class="panel-header panel-header-sm">
             </div>

             <div class="content">
                 @yield('content')


             </div>

             <!-- <footer class="footer">
                 <div class="container-fluid">
                     <nav>
                         <ul>
                             <li>

                                 My Truck
                                 </a>
                             </li>
                             <li>

                                 About Us
                                 </a>
                             </li>
                             <li>

                                 Blog
                                 </a>
                             </li>
                         </ul>
                     </nav>
                     <div class="copyright">
                         &copy;
                         <script>
                         document.write(new Date().getFullYear())
                         </script>, Designed by
                         <a href="" target="_blank">Robera</a>. Coded by
                         <a href="" target="_blank">Creative roba</a>.
                     </div>
                 </div>
             </footer> -->
         </div>
     </div>

     @yield('scripts')
 </body>
 <!--   Core JS Files   -->
 <script src="../assets/js/core/jquery.min.js"></script>
 <script src="../assets/js/core/popper.min.js"></script>
 <script src="../assets/js/core/bootstrap.min.js"></script>
 <script src="../assets/js/plugins/perfect-scrollbar.jquery.min.js"></script>
 <!--  Plugin for Switches, full documentation here: http://www.jque.re/plugins/version3/bootstrap.switch/ -->
 <script src="../assets/js/plugins/bootstrap-switch.js"></script>
 <!--  Google Maps Plugin    -->
 <script src="https://maps.googleapis.com/maps/api/js?key=YOUR_KEY_HERE"></script>
 <!-- Chart JS -->
 <script src="../assets/js/plugins/chartjs.min.js"></script>
 <!--  Notifications Plugin    -->
 <script src="../assets/js/plugins/bootstrap-notify.js"></script>
 <!-- Control Center for Now Ui Dashboard: parallax effects, scripts for the example pages etc -->
 <script src="../assets/js/now-ui-dashboard.js?v=1.0.0"></script>
 <!-- Now Ui Dashboard DEMO methods, don't include it in your project! -->
 <script src="../assets/demo/demo.js"></script>

 </html>