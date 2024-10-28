// import 'package:flutter/material.dart';
// import 'package:font_awesome_flutter/font_awesome_flutter.dart';
// import 'sidebarProfile.dart';
// import 'sidebarWallet.dart';
// import 'sidebarMyOrder.dart';
// import 'sidebarSettings.dart';

// class NavigationDrawer extends StatelessWidget {
//   final Function onProfileTap;
//   final Function onWalletTap;
//   final Function onMyOrdersTap;
//   final Function onSettingsTap;
//   final File? profileImage;
//   final Function onImagePick;

//   NavigationDrawer({
//     required this.onProfileTap,
//     required this.onWalletTap,
//     required this.onMyOrdersTap,
//     required this.onSettingsTap,
//     required this.profileImage,
//     required this.onImagePick,
//   });

//   @override
//   Widget build(BuildContext context) {
//     return Drawer(
//       child: Column(
//         children: [
//           DrawerHeader(
//             decoration: BoxDecoration(
//               gradient: LinearGradient(
//                 colors: [Colors.black, Colors.grey.shade800],
//                 begin: Alignment.topCenter,
//                 end: Alignment.bottomCenter,
//               ),
//             ),
//             child: Row(
//               children: [
//                 GestureDetector(
//                   onTap: () => onImagePick(),
//                   child: CircleAvatar(
//                     radius: 40,
//                     backgroundColor: Colors.white,
//                     child: profileImage == null
//                         ? Icon(FontAwesomeIcons.user, size: 40, color: Colors.grey)
//                         : ClipOval(
//                             child: Image.file(
//                               profileImage!,
//                               fit: BoxFit.cover,
//                               width: 80,
//                               height: 80,
//                             ),
//                           ),
//                   ),
//                 ),
//                 SizedBox(width: 15),
//                 Text(
//                   'Welcome, User!',
//                   style: TextStyle(
//                     color: Colors.white,
//                     fontSize: 22,
//                     fontWeight: FontWeight.bold,
//                   ),
//                 ),
//               ],
//             ),
//           ),
//           Expanded(
//             child: ListView(
//               children: [
//                 _buildDrawerItem(FontAwesomeIcons.user, 'Profile', onProfileTap),
//                 _buildDrawerItem(FontAwesomeIcons.wallet, 'Wallet', onWalletTap),
//                 _buildDrawerItem(FontAwesomeIcons.shoppingCart, 'My Orders', onMyOrdersTap),
//                 _buildDrawerItem(FontAwesomeIcons.cog, 'Settings', onSettingsTap),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildDrawerItem(IconData icon, String title, Function onTap) {
//     return ListTile(
//       leading: Icon(icon, color: Colors.black),
//       title: Text(
//         title,
//         style: TextStyle(
//           fontSize: 18,
//           color: Colors.black,
//           fontWeight: FontWeight.bold,
//         ),
//       ),
//       tileColor: Colors.grey[200],
//       onTap: () {
//         onTap();
//       },
//     );
//   }
// }
