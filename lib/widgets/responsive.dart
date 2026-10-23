import 'package:flutter/material.dart';

const double wideBreakpoint = 600;

bool isWide(BuildContext context) =>
    MediaQuery.sizeOf(context).width >= wideBreakpoint;
