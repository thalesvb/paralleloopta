*&---------------------------------------------------------------------*
*& Report  YTVBP_OOPTA_DEMO_01
*&
*&---------------------------------------------------------------------*
*&
*&
*&---------------------------------------------------------------------*
report zproota_demo_01.
*&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&
*
* Demonstração de um problem que pode ser resolvido por divisão
* e conquista.
* Divisão e conquista: https://en.wikipedia.org/wiki/Divide_and_conquer_algorithm
*
* Neste caso, se trata de uma ordenação em uma partição, em que
* subpartições são ordenadas em paralelos e então a lista final`
* é montada com base no princípio do MergeSort.
* Sim, a instrução SORT existe na linguagem, mas aqui é demonstrado
* uma implementação para solucionar um problema de fácil entendimento.
*
*&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&

class lcl_parallel_sorting definition.
  public section.
    interfaces zif_proota_parallel_code.
    methods init_data.
    methods merge_partition
      importing it_sorted_values type index table.
    data:
      m_sorted_numbers   type standard table of i read-only,
      m_unsorted_numbers type standard table of i read-only.
  private section.
    data:
      m_current_block    type i value 0.

endclass.
class lcl_parallel_sorting implementation.
  method init_data.
    data(rnd) = cl_abap_random_int=>create( ).
    do 20 times.
      append rnd->get_next( ) to m_unsorted_numbers.
    enddo.
  endmethod.
  method zif_proota_parallel_code~context_input.
    create data er_data type standard table of i.
  endmethod.
  method zif_proota_parallel_code~context_output.
    create data er_data type standard table of i.
  endmethod.
  method zif_proota_parallel_code~fetch_block_data.
    constants:
      lc_block_size type i value 5.
    data:
      lr_block type ref to i.

    field-symbols:
      <r> type data,
      <t> type index table.
    if block_id is initial.
      get reference of m_current_block into lr_block.
    else.
      create data lr_block.
      lr_block->* = block_id.
    endif.

    if lr_block->* gt ( lines( m_unsorted_numbers ) div lc_block_size ).
      return.
    else.
      ev_block_id = lr_block->*.
    endif.

    zif_proota_parallel_code~context_input(
      importing
        er_data = e_data
    ).
    assign e_data->* to <t>.

    loop at m_unsorted_numbers assigning <r>
      from lr_block->* * lc_block_size + 1
      to ( lr_block->* + 1 ) * lc_block_size.
      append <r> to <t>.
    endloop.

    add 1 to lr_block->*.
  endmethod.
  method zif_proota_parallel_code~merge.
    field-symbols:
      <t> type index table.
    assign ctx->* to <t>.
    merge_partition( it_sorted_values = <t> ).
  endmethod.
  method zif_proota_parallel_code~worker.
    field-symbols:
      <i> type index table,
      <e> type index table.
    assign:
      i_ctx->* to <i>,
      e_ctx->* to <e>.
    sort <i>.
    <e> = <i>.
  endmethod.
  method merge_partition.
    field-symbols:
      <main_value>      type i,
      <partition_value> type i.
    data:
      main_part_idx type i value 1,
      sort_part_idx type i value 1.

    read table:
      m_sorted_numbers assigning <main_value> index main_part_idx,
      it_sorted_values assigning <partition_value> index sort_part_idx.

    while <partition_value> is assigned.
      while <main_value> is assigned and
            <main_value> le <partition_value>.
        add 1 to main_part_idx.
        read table m_sorted_numbers assigning <main_value> index main_part_idx.
        if sy-subrc ne 0.
          unassign <main_value>.
        endif.
      endwhile.
      insert <partition_value> into m_sorted_numbers index main_part_idx.
      add 1 to sort_part_idx.
      read table m_sorted_numbers assigning <main_value> index main_part_idx.
      read table it_sorted_values assigning <partition_value> index sort_part_idx.
      if sy-subrc ne 0.
        unassign <partition_value>.
      endif.
    endwhile.

  endmethod.
endclass.

start-of-selection.

  break-point.
  data(parallel_sorting) = new lcl_parallel_sorting( ).
  parallel_sorting->init_data( ).
  new zcl_proota_parallel_runner( parallel_sorting )->run( ).
  break-point.
