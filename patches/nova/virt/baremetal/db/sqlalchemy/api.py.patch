239a240,261
> def bm_node_destroy_by_node_uuid(context, bm_node_uuid):
>     # Delete all interfaces belonging to the node.
>     # Delete physically since these have unique columns.
>     session = db_session.get_session()
>     with session.begin():
>         node = model_query(context, models.BareMetalNode, read_deleted="no").\
>             filter_by(uuid=bm_node_uuid).first()
>         rows = model_query(context, models.BareMetalNode, read_deleted="no").\
>             filter_by(id=node['id']).\
>             update({'deleted': True,
>                     'deleted_at': timeutils.utcnow(),
>                     'updated_at': literal_column('updated_at')})
> 
>         model_query(context, models.BareMetalInterface, read_deleted="no").\
>             filter_by(bm_node_id=node['id']).\
>             delete()
> 
>         if not rows:
>             raise exception.NodeNotFoundByUUID(node_uuid=bm_node_uuid)
> 
> 
> @sqlalchemy_api.require_admin_context
