40c40
<         d[f] = node_ref.get(f)
---
>         d[f] = node_ref.get(f) if not f == "id" else node_ref.get("uuid")
118,119c118,119
<             node = db.bm_node_get(context, id)
<         except exception.NodeNotFound:
---
>             node = db.bm_node_get_by_node_uuid(context, id)
>         except exception.NodeNotFoundByUUID:
120a121
> 
122c123
<             ifs = db.bm_interface_get_all_by_bm_node_id(context, id)
---
>             ifs = db.bm_interface_get_all_by_bm_node_id(context, node['id'])
124a126
> 
135a138
>         id = node.get('id')
139c142
<                                            bm_node_id=node['id'],
---
>                                            bm_node_id=id,
153,154c156,157
<             db.bm_node_destroy(context, id)
<         except exception.NodeNotFound:
---
>             db.bm_node_destroy_by_node_uuid(context, id)
>         except exception.NodeNotFoundByUUID:
158c161
<     def _check_node_exists(self, context, node_id):
---
>     def _check_node_exists(self, context, node_uuid):
160,161c163,164
<             db.bm_node_get(context, node_id)
<         except exception.NodeNotFound:
---
>             return db.bm_node_get_by_node_uuid(context, node_uuid)
>         except exception.NodeNotFoundByUUID:
169c172
<         self._check_node_exists(context, id)
---
>         node = self._check_node_exists(context, id)
175c178
<                                        bm_node_id=id,
---
>                                        bm_node_id=node['id'],
187c190
<         self._check_node_exists(context, id)
---
>         node = self._check_node_exists(context, id)
194c197
<         ifs = db.bm_interface_get_all_by_bm_node_id(context, id)
---
>         ifs = db.bm_interface_get_all_by_bm_node_id(context, node['id'])
