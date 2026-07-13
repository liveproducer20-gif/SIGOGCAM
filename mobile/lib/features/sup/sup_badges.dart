import 'package:flutter/material.dart';

Color supportPriorityColor(String value) => switch(value){'Crítica'=>const Color(0xFFDC2626),'Alta'=>const Color(0xFFF97316),'Media'=>const Color(0xFFEAB308),_=>const Color(0xFF16A34A)};
Color supportStatusColor(String value) => switch(value){'Nuevo'=>const Color(0xFFEF4444),'En proceso'=>const Color(0xFFF97316),'Pendiente'=>const Color(0xFFEAB308),'Resuelto'=>const Color(0xFF16A34A),_=>const Color(0xFF64748B)};

class SupportBadge extends StatelessWidget {
  final String label;
  final Color color;
  final IconData? icon;
  const SupportBadge({super.key,required this.label,required this.color,this.icon});
  @override Widget build(BuildContext context)=>Container(
    padding:const EdgeInsets.symmetric(horizontal:9,vertical:5),
    decoration:BoxDecoration(color:color.withValues(alpha:.12),borderRadius:BorderRadius.circular(20)),
    child:Row(mainAxisSize:MainAxisSize.min,children:[if(icon!=null)...[Icon(icon,size:13,color:color),const SizedBox(width:4)],Text(label,style:TextStyle(color:color,fontSize:11,fontWeight:FontWeight.w700))]),
  );
}

class SupportStatusBadge extends SupportBadge { SupportStatusBadge(String value,{super.key}):super(label:value,color:supportStatusColor(value)); }
class SupportPriorityBadge extends SupportBadge { SupportPriorityBadge(String value,{super.key}):super(label:value,color:supportPriorityColor(value),icon:Icons.warning_amber_rounded); }

