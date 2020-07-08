interface zif_proota_parallel_code
  public .


  types gty_block_id type spta_t_object_id .
  types gty_context_input type ref to data .
  types gty_context_output type ref to data .

  class-methods worker
    importing
      !i_ctx type gty_context_input
    exporting
      !e_ctx type gty_context_output .
  class-methods context_input
    exporting
      !er_data type gty_context_input .
  class-methods context_output
    exporting
      !er_data type gty_context_output .
  methods fetch_block_data
    importing
      !block_id    type gty_block_id optional
    exporting
      !ev_block_id type gty_block_id
      !e_data      type gty_context_input .
  methods merge
    importing
      !ctx type gty_context_output .
endinterface.
