import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../data/event_workspace_repository.dart';
import 'create_resource_page.dart';
import 'ticket_detail_page.dart';
import '../resource_mode.dart';

class ResourceListPage extends StatelessWidget {
  const ResourceListPage({required this.title, required this.loader, required this.mode, required this.eventId, required this.repository, super.key});
  final String title;
  final Future<Object> loader;
  final ResourceMode mode;
  final int eventId;
  final EventWorkspaceRepository repository;

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: Text(title)),
        floatingActionButton: mode == ResourceMode.incidents || mode == ResourceMode.tickets
            ? FloatingActionButton(
                onPressed: () => Navigator.of(context).push(MaterialPageRoute<bool>(builder: (_) => CreateResourcePage(mode: mode, eventId: eventId, repository: repository))),
                child: const Icon(Icons.add),
              )
            : null,
        body: FutureBuilder<Object>(future: loader, builder: (context, snapshot) {
          if (snapshot.hasError) return Center(child: Text('${snapshot.error}'));
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          return switch (mode) {
            ResourceMode.readiness => _Readiness(data: snapshot.data! as Map<String, dynamic>, eventId: eventId, repository: repository),
            ResourceMode.live => _Live(data: snapshot.data! as Map<String, dynamic>),
            ResourceMode.report => _Report(data: snapshot.data! as Map<String, dynamic>),
            _ => _List(data: snapshot.data! as List<dynamic>, mode: mode, eventId: eventId, repository: repository),
          };
        }),
      );
}

class _Readiness extends StatelessWidget {
  const _Readiness({required this.data, required this.eventId, required this.repository});
  final Map<String, dynamic> data;
  final int eventId;
  final EventWorkspaceRepository repository;
  @override Widget build(BuildContext context) => ListView(padding: const EdgeInsets.all(16), children: [
    _Score(score: data['score'] as int, label: '${data['status']} · ${data['critical_blockers_count']} critical blockers'),
    const SizedBox(height: 18),
    ...(data['dimensions'] as List).map((raw) { final item = raw as Map<String, dynamic>; return Card(child: ListTile(onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => _DimensionPage(title: item['label'] as String, loader: repository.dimension(eventId, item['key'] as String)))), title: Text(item['label'] as String), subtitle: Text('${item['ready']}/${item['total']} ready · ${item['actions_required']} actions'), trailing: Text('${item['score']}%', style: TextStyle(color: _statusColor(item['status'] as String), fontWeight: FontWeight.w700)))); }),
  ]);
}

class _DimensionPage extends StatelessWidget { const _DimensionPage({required this.title, required this.loader}); final String title; final Future<Map<String, dynamic>> loader; @override Widget build(BuildContext context) => Scaffold(appBar: AppBar(title: Text(title)), body: FutureBuilder<Map<String, dynamic>>(future: loader, builder: (context, snapshot) { if(snapshot.hasError)return Center(child: Text('${snapshot.error}')); if(!snapshot.hasData)return const Center(child: CircularProgressIndicator()); final items=snapshot.data!['items'] as List; return ListView.separated(padding: const EdgeInsets.all(16), itemCount: items.length, separatorBuilder:(_,__)=>const SizedBox(height:8), itemBuilder:(context,index){final item=items[index] as Map<String,dynamic>; return Card(child: ListTile(leading:Icon(Icons.circle,size:12,color:_statusColor(item['status'] as String)),title:Text(item['label'] as String),subtitle:Text(item['message'] as String? ?? 'No action required'),trailing:Text(item['status'] as String)));}); })); }

class _List extends StatelessWidget {
  const _List({required this.data, required this.mode, required this.eventId, required this.repository});
  final List<dynamic> data; final ResourceMode mode; final int eventId; final EventWorkspaceRepository repository;
  @override Widget build(BuildContext context) { if(data.isEmpty)return const Center(child:Text('Nothing to show.',style:TextStyle(color:AppColors.muted))); return ListView.separated(padding:const EdgeInsets.all(16),itemCount:data.length,separatorBuilder:(_,__)=>const SizedBox(height:8),itemBuilder:(context,index){final item=data[index] as Map<String,dynamic>; final info=_info(item); return Card(child:ListTile(leading:Icon(info.$3,color:info.$4),title:Text(info.$1),subtitle:Text(info.$2),trailing:const Icon(Icons.chevron_right),onTap:(){if(mode==ResourceMode.tickets){Navigator.of(context).push(MaterialPageRoute<void>(builder:(_)=>TicketDetailPage(ticketId:item['id'] as int,repository:repository)));return;}final Future<Object>? detail=switch(mode){ResourceMode.teams=>repository.team(eventId,(item['team'] as Map<String,dynamic>)['id'] as int),ResourceMode.incidents=>repository.incident(item['id'] as int),_=>null};if(detail!=null)Navigator.of(context).push(MaterialPageRoute<void>(builder:(_)=>_JsonDetailPage(title:info.$1,loader:detail)));}));}); }
  (String,String,IconData,Color) _info(Map<String,dynamic> item)=>switch(mode){
    ResourceMode.teams=>((item['team'] as Map<String,dynamic>)['name'] as String,'${item['score']}% · ${item['blockers_count']} blockers',Icons.groups_outlined,_statusColor(item['status'] as String)),
    ResourceMode.incidents=>(item['title'] as String,'${item['severity']} · ${item['status']}',Icons.warning_amber,_severityColor(item['severity'] as String)),
    ResourceMode.tickets=>('${item['reference']} · ${item['subject']}','${item['priority']} · ${item['status']} · SLA ${item['sla_status']}',Icons.support_agent,_statusColor(item['sla_status'] as String)),
    ResourceMode.activity=>(item['title'] as String,item['description'] as String,Icons.history,AppColors.muted),
    _=>('Item','',Icons.circle,AppColors.muted),
  };
}

class _Live extends StatelessWidget { const _Live({required this.data}); final Map<String,dynamic> data; @override Widget build(BuildContext context){final progress=data['progress'] as Map<String,dynamic>; return ListView(padding:const EdgeInsets.all(16),children:[_Score(score: progress['total']==0?0:((progress['completed'] as int)*100/(progress['total'] as int)).round(),label:'${progress['completed']} of ${progress['total']} matches complete'),...['live_matches','next_matches','delayed_matches','operational_incidents'].map((key)=>Card(child:ListTile(title:Text(key.replaceAll('_',' ').toUpperCase()),trailing:Text('${(data[key] as List).length}'))))]); } }
class _Report extends StatelessWidget { const _Report({required this.data}); final Map<String,dynamic> data; @override Widget build(BuildContext context){final support=data['support'] as Map<String,dynamic>;final incidents=data['incidents'] as Map<String,dynamic>;return ListView(padding:const EdgeInsets.all(16),children:[_Score(score:((data['readiness'] as Map<String,dynamic>)['score_before_kickoff'] as int?)??0,label:'Readiness before kickoff'),_MetricCard(title:'Matches',value:'${data['match_count']}'),_MetricCard(title:'Incidents',value:'${incidents['total']}'),_MetricCard(title:'Support tickets',value:'${support['tickets']}'),const SizedBox(height:16),const Text('Recommendations',style:TextStyle(fontSize:20,fontWeight:FontWeight.w700)),...(data['recommendations'] as List).map((item)=>ListTile(leading:const Icon(Icons.lightbulb_outline,color:AppColors.coral),title:Text(item as String)))]); } }
class _JsonDetailPage extends StatelessWidget { const _JsonDetailPage({required this.title,required this.loader}); final String title;final Future<Object> loader; @override Widget build(BuildContext context)=>Scaffold(appBar:AppBar(title:Text(title)),body:FutureBuilder<Object>(future:loader,builder:(context,snapshot){if(snapshot.hasError)return Center(child:Text('${snapshot.error}'));if(!snapshot.hasData)return const Center(child:CircularProgressIndicator());final data=snapshot.data! as Map<String,dynamic>;return ListView(padding:const EdgeInsets.all(16),children:data.entries.where((entry)=>entry.value is! Map&&entry.value is! List).map((entry)=>Card(child:ListTile(title:Text(entry.key.replaceAll('_',' ')),subtitle:Text('${entry.value??'—'}')))).toList();})); }
class _Score extends StatelessWidget { const _Score({required this.score,required this.label});final int score;final String label;@override Widget build(BuildContext context)=>Container(padding:const EdgeInsets.all(20),decoration:BoxDecoration(color:AppColors.surface,border:Border.all(color:AppColors.border),borderRadius:BorderRadius.circular(16),boxShadow:const [BoxShadow(color:Color(0x59000000),blurRadius:24,offset:Offset(0,10))]),child:Row(children:[Text('$score%',style:const TextStyle(fontSize:38,fontWeight:FontWeight.w800,color:AppColors.lime)),const SizedBox(width:18),Expanded(child:Text(label,style:const TextStyle(color:AppColors.muted)))])); }
class _MetricCard extends StatelessWidget { const _MetricCard({required this.title,required this.value});final String title;final String value;@override Widget build(BuildContext context)=>Card(child:ListTile(title:Text(title),trailing:Text(value,style:const TextStyle(fontSize:22,fontWeight:FontWeight.w700)))); }
Color _statusColor(String status)=>switch(status){'ready'||'met'||'on_track'=>AppColors.lime,'warning'||'approaching'=>Colors.orange,'blocked'||'breached'=>Colors.redAccent,_=>AppColors.muted};
Color _severityColor(String severity)=>switch(severity){'critical'=>Colors.red,'high'=>Colors.deepOrange,'medium'=>Colors.orange,_=>AppColors.muted};
