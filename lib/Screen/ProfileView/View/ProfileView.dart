import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mathlab_admin/Constants/AppColor.dart';
import 'package:mathlab_admin/Constants/functionsupporter.dart';
import 'package:mathlab_admin/Screen/ProfileView/Model/UserListModel.dart';
import 'package:mathlab_admin/Screen/ProfileView/Model/UserProfileModel.dart';
import 'package:mathlab_admin/Screen/ProfileView/Service/controller.dart';
import 'package:mathlab_admin/Screen/ProfileView/View/AdvanceFilterView.dart';
import 'package:mathlab_admin/Screen/ProfileView/View/IndividualCourseAdd.dart';
import 'package:mathlab_admin/Screen/ProfileView/View/IndividualProfileView.dart';
import 'package:mathlab_admin/Screen/ProfileView/View/MultiStudentCourseAdd.dart';
import 'package:mathlab_admin/Screen/ProfileView/View/UserDetailsView.dart';

class ProfileViewScreen extends StatefulWidget {
  ProfileViewScreen({super.key});

  @override
  State<ProfileViewScreen> createState() => _ProfileViewScreenState();
}

class _ProfileViewScreenState extends State<ProfileViewScreen> {
  TextEditingController usernameController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  bool _showSuggestions = false;

  ProfileController pctrl = Get.put(ProfileController());

  @override
  void initState() {
    super.initState();
    // Listen to search field changes for suggestions
    usernameController.addListener(_onSearchChanged);
    
    // Hide suggestions when search field loses focus
    _searchFocusNode.addListener(() {
      if (!_searchFocusNode.hasFocus) {
        Future.delayed(Duration(milliseconds: 200), () {
          if (mounted) {
            setState(() {
              _showSuggestions = false;
            });
          }
        });
      } else {
        // Show suggestions when field gains focus if there's text
        if (usernameController.text.isNotEmpty) {
          pctrl.updateSearchSuggestions(usernameController.text);
          setState(() {
            _showSuggestions = pctrl.searchSuggestions.isNotEmpty;
          });
        }
      }
    });
  }

  void _onSearchChanged() {
    final query = usernameController.text.trim();
    if (query.isNotEmpty) {
      pctrl.updateSearchSuggestions(query);
      // Show suggestions after a brief delay to allow suggestions to update
      Future.delayed(Duration(milliseconds: 50), () {
        if (mounted) {
          setState(() {
            _showSuggestions = pctrl.searchSuggestions.isNotEmpty;
          });
        }
      });
    } else {
      setState(() {
        _showSuggestions = false;
      });
    }
  }

  @override
  void dispose() {
    usernameController.removeListener(_onSearchChanged);
    usernameController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GetBuilder<ProfileController>(builder: (_) {
      return Container(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (pctrl.selectedProfileModel != null)
                  InkWell(
                    onTap: () {
                      pctrl.selectedProfileModel = null;
                      pctrl.update();
                    },
                    child: Icon(
                      Icons.arrow_back_ios_new,
                      size: 20,
                    ),
                  ),
                if (pctrl.selectedProfileModel != null)
                  SizedBox(
                    width: 10,
                  ),
                tx700("Users ", size: 25, color: Colors.black54),
                Expanded(child: Container()),
                // InkWell(
                //     onTap: () {
                //       pctrl.loadProfiles();
                //     },
                //     child: Icon(Icons.replay_outlined)),
                width(10),
                if (pctrl.selectedProfileModel != null)
                  InkWell(
                    onTap: () {
                      showDialog(
                          context: context,
                          builder: (context) => Container(
                              alignment: Alignment.center,
                              child: IndividualCoureseAdd()));
                    },
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                      decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          color: primaryColor),
                      child: Row(
                        children: [
                          Icon(
                            Icons.add,
                            color: Colors.white,
                          ),
                          tx600("Add Course", color: Colors.white)
                        ],
                      ),
                    ),
                  ),
                // if (pctrl.selectedProfileModel == null)
                //   InkWell(
                //     onTap: () {
                //       showDialog(
                //           context: context,
                //           builder: (context) => Container(
                //               alignment: Alignment.center,
                //               child: MultiStudentCourseAdd()));
                //     },
                //     child: Container(
                //       padding: EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                //       decoration: BoxDecoration(
                //           borderRadius: BorderRadius.circular(12),
                //           color: primaryColor),
                //       child: Row(
                //         children: [
                //           Icon(
                //             Icons.add,
                //             color: Colors.white,
                //           ),
                //           tx600("Group Add", color: Colors.white)
                //         ],
                //       ),
                //     ),
                //   ),
                width(10),
                Stack(
                  children: [
                    Container(
                      width: 250,
                      height: 30,
                      decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all()),
                      alignment: Alignment.center,
                      child: TextField(
                        controller: usernameController,
                        focusNode: _searchFocusNode,
                        textAlign: TextAlign.start,
                        decoration: InputDecoration(
                            border: InputBorder.none,
                            hintText: "Search by name, email, or phone",
                            prefixIcon: Icon(Icons.search),
                            isDense: true),
                        onChanged: (value) {
                          if (value.isNotEmpty) {
                            pctrl.updateSearchSuggestions(value);
                            // Update state after controller updates
                            Future.microtask(() {
                              if (mounted) {
                                setState(() {
                                  _showSuggestions = pctrl.searchSuggestions.isNotEmpty;
                                });
                              }
                            });
                          } else {
                            setState(() {
                              _showSuggestions = false;
                            });
                          }
                        },
                        onSubmitted: (value) {
                          setState(() {
                            _showSuggestions = false;
                          });
                          pctrl.loadProfiles(search: value, paidOnly: pctrl.paidOnlyFilter);
                        },
                        onTap: () {
                          if (usernameController.text.isNotEmpty && pctrl.searchSuggestions.isNotEmpty) {
                            setState(() {
                              _showSuggestions = true;
                            });
                          }
                        },
                      ),
                    ),
                    // Suggestions dropdown - wrapped in GetBuilder to update when suggestions change
                    GetBuilder<ProfileController>(
                      builder: (controller) {
                        final shouldShow = _showSuggestions && 
                                         usernameController.text.isNotEmpty && 
                                         controller.searchSuggestions.isNotEmpty;
                        
                        if (!shouldShow) {
                          return SizedBox.shrink();
                        }
                        
                        return Positioned(
                          top: 35,
                          left: 0,
                          right: 0,
                          child: Material(
                            elevation: 4,
                            borderRadius: BorderRadius.circular(8),
                            color: Colors.transparent,
                            child: Container(
                              constraints: BoxConstraints(maxHeight: 200),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.grey.shade300),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black26,
                                    blurRadius: 4,
                                    offset: Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: ListView.builder(
                                shrinkWrap: true,
                                padding: EdgeInsets.zero,
                                itemCount: controller.searchSuggestions.length,
                                itemBuilder: (context, index) {
                                  final suggestion = controller.searchSuggestions[index];
                                  return InkWell(
                                    onTap: () {
                                      usernameController.text = suggestion;
                                      setState(() {
                                        _showSuggestions = false;
                                      });
                                      _searchFocusNode.unfocus();
                                      controller.loadProfiles(search: suggestion, paidOnly: controller.paidOnlyFilter);
                                    },
                                    child: Container(
                                      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                      decoration: BoxDecoration(
                                        border: Border(
                                          bottom: BorderSide(
                                            color: Colors.grey.shade200,
                                            width: index < controller.searchSuggestions.length - 1 ? 1 : 0,
                                          ),
                                        ),
                                      ),
                                      child: Row(
                                        children: [
                                          Icon(Icons.search, size: 16, color: Colors.grey),
                                          SizedBox(width: 8),
                                          Expanded(
                                            child: tx500(suggestion, size: 14),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
                width(10),
                GetBuilder<ProfileController>(
                  builder: (controller) {
                    return InkWell(
                      onTap: () {
                        controller.paidOnlyFilter = !controller.paidOnlyFilter;
                        controller.update();
                        // Reload with current search and course filter, but with updated paid filter
                        controller.loadProfiles(
                          search: usernameController.text, 
                          paidOnly: controller.paidOnlyFilter
                        );
                      },
                      child: Container(
                        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                        decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            color: controller.paidOnlyFilter ? primaryColor : Colors.grey,
                            border: Border.all(color: primaryColor)),
                        child: Row(
                          children: [
                            Icon(
                              controller.paidOnlyFilter ? Icons.check_circle : Icons.circle_outlined,
                              color: Colors.white,
                              size: 16,
                            ),
                            width(5),
                            tx600("Paid Only", color: Colors.white, size: 12)
                          ],
                        ),
                      ),
                    );
                  },
                ),
                width(10),
                InkWell(
                  onTap: () {
                    pctrl.loadProfiles(search: usernameController.text, paidOnly: pctrl.paidOnlyFilter);
                  },
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                    decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        color: primaryColor),
                    child: Row(
                      children: [
                        Icon(
                          Icons.search,
                          color: Colors.white,
                        ),
                        tx600("Search", color: Colors.white)
                      ],
                    ),
                  ),
                ),
                width(20)
              ],
            ),
            height(30),
            Expanded(
                child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        (pctrl.selectedProfileModel != null)
                            ? IndividualProfileView()
                            : DataTable(
                                showBottomBorder: true,
                                columnSpacing: 0,
                                horizontalMargin: 0,
                                headingRowHeight: 50,
                                columns: [
                                    // DataColumn(
                                    //   label: Container(
                                    //       width: 90,
                                    //       height: 40,
                                    //       alignment: Alignment.center,
                                    //       padding: EdgeInsets.all(2),
                                    //       color: Colors.grey.withOpacity(.1),
                                    //       child: tx600("ID")),
                                    // ),
                                    DataColumn(
                                      label: InkWell(
                                        onTap: () => pctrl.sortUsers('name'),
                                        child: Container(
                                            width: 200,
                                            height: 40,
                                            alignment: Alignment.center,
                                            padding: EdgeInsets.all(2),
                                            color: Colors.grey.withOpacity(.1),
                                            child: Row(
                                              mainAxisAlignment: MainAxisAlignment.center,
                                              children: [
                                                tx600("Student Names"),
                                                if (pctrl.sortColumn == 'name')
                                                  Icon(
                                                    pctrl.sortAscending 
                                                        ? Icons.arrow_upward 
                                                        : Icons.arrow_downward,
                                                    size: 16,
                                                    color: Colors.blue,
                                                  ),
                                              ],
                                            )),
                                      ),
                                    ),
                                    DataColumn(
                                      label: InkWell(
                                        onTap: () => pctrl.sortUsers('phone'),
                                        child: Container(
                                            width: 150,
                                            height: 40,
                                            alignment: Alignment.center,
                                            padding: EdgeInsets.all(2),
                                            color: Colors.grey.withOpacity(.1),
                                            child: Row(
                                              mainAxisAlignment: MainAxisAlignment.center,
                                              children: [
                                                tx600("Contact Number"),
                                                if (pctrl.sortColumn == 'phone')
                                                  Icon(
                                                    pctrl.sortAscending 
                                                        ? Icons.arrow_upward 
                                                        : Icons.arrow_downward,
                                                    size: 16,
                                                    color: Colors.blue,
                                                  ),
                                              ],
                                            )),
                                      ),
                                    ),
                                    DataColumn(
                                      label: InkWell(
                                        onTap: () => pctrl.sortUsers('enrolled'),
                                        child: Container(
                                            width: 200,
                                            height: 40,
                                            alignment: Alignment.center,
                                            padding: EdgeInsets.all(2),
                                            color: Colors.grey.withOpacity(.1),
                                            child: Row(
                                              mainAxisAlignment: MainAxisAlignment.center,
                                              children: [
                                                tx600("Enrolled"),
                                                if (pctrl.sortColumn == 'enrolled')
                                                  Icon(
                                                    pctrl.sortAscending 
                                                        ? Icons.arrow_upward 
                                                        : Icons.arrow_downward,
                                                    size: 16,
                                                    color: Colors.blue,
                                                  ),
                                              ],
                                            )),
                                      ),
                                    ),
                                    DataColumn(
                                      label: InkWell(
                                        onTap: () => pctrl.sortUsers('email'),
                                        child: Container(
                                            width: 300,
                                            height: 40,
                                            alignment: Alignment.center,
                                            padding: EdgeInsets.all(2),
                                            color: Colors.grey.withOpacity(.1),
                                            child: Row(
                                              mainAxisAlignment: MainAxisAlignment.center,
                                              children: [
                                                tx600("Email ID"),
                                                if (pctrl.sortColumn == 'email')
                                                  Icon(
                                                    pctrl.sortAscending 
                                                        ? Icons.arrow_upward 
                                                        : Icons.arrow_downward,
                                                    size: 16,
                                                    color: Colors.blue,
                                                  ),
                                              ],
                                            )),
                                      ),
                                    ),
                                  ],
                                rows: [
                                    for (UserListModel data
                                        in pctrl.SearchStudentList)
                                      DataRow(cells: [
                                        DataCell(InkWell(
                                          onTap: () {
                                            pctrl.selectedProfileModel = data;
                                            pctrl.fetchUser(data.username!);
                                            pctrl.update();
                                          },
                                          child: Container(
                                              width: 180,
                                              margin: EdgeInsets.only(left: 20),
                                              height: 40,
                                              alignment: Alignment.centerLeft,
                                              padding: EdgeInsets.all(2),
                                              child: tx600("${data.name}")),
                                        )),
                                        DataCell(Container(
                                            width: 150,
                                            height: 40,
                                            alignment: Alignment.center,
                                            padding: EdgeInsets.all(2),
                                            child:
                                                tx600("${data.phoneNumber}"))),
                                        DataCell(Container(
                                            width: 200,
                                            height: 40,
                                            alignment: Alignment.center,
                                            padding: EdgeInsets.all(2),
                                            child: tx600(data
                                                .countOfCoursesPurchased!
                                                .toString()))),
                                        DataCell(Container(
                                            width: 300,
                                            height: 40,
                                            alignment: Alignment.center,
                                            padding: EdgeInsets.all(2),
                                            child: tx600("${data.username}"))),
                                      ])
                                  ]),
                        SizedBox(
                          height: 20,
                        ),
                        if (pctrl.selectedProfileModel == null &&
                            pctrl.profileDatas != null &&
                            pctrl.profileDatas["next"] != null)
                          Container(
                              padding: EdgeInsets.only(right: 200),
                              alignment: Alignment.center,
                              child: InkWell(
                                onTap: () {
                                  pctrl.loadProfilesMore();
                                },
                                child: tx600("Load More"),
                              )),
                        SizedBox(
                          height: 20,
                        ),
                      ],
                    ),
                  ),
                ),
                if (pctrl.selectedProfileModel == null) 
                  Advancefilterview()
                else 
                  UserDetailsView()
              ],
            )),
          ],
        ),
      );
    });
  }
}
