report zproota_demo_01.
*&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&
*
* Parallel processing to solve a Divide and Conquer problem.
* https://en.wikipedia.org/wiki/Divide_and_conquer_algorithm
*
* This code solves a sorting problem by dividing the entire data
* universe into parallelized sub-partitions, sort each one, and merge
* it to build the sorted universe, using MergeSort principle.
*
* Yes, we already have SORT statement baked into language syntax,
* but this is a simple business-agnostic problem to allow peeking
* and debug.
*
*&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&

class lcl_parallel_sorting definition.
  public section.
    interfaces zif_proota_parallel_code.
    methods init_data
      importing random_numbers_to_generate type i
                partition_size type i.
    methods print_results.
  private section.
    types: input_object type standard table of i with default key.
    types: output_object type standard table of i with default key.
    data:
      random_numbers type standard table of i,
      sorted_numbers   type standard table of i.
    data: partition_size type i.
    data: task_id_counter    type i value 0.
    data: begin of statistics,
            tasks_created type i,
            end of statistics.
    methods merge_partition
      importing sorted_partition type output_object.

endclass.
class lcl_parallel_sorting implementation.
  method init_data.
    data(rnd) = cl_abap_random_int=>create( seed = conv #( sy-uzeit ) ).
    do random_numbers_to_generate times.
      append rnd->get_next( ) to random_numbers.
    enddo.
    me->partition_size = partition_size.
  endmethod.
  method zif_proota_parallel_code~create_context_input_object.
    create data context type input_object.
  endmethod.
  method zif_proota_parallel_code~create_context_output_object.
    create data context type output_object.
  endmethod.
  method zif_proota_parallel_code~prepare_task_input.
    data:
      requested_task_id type ref to i.

    if request_task_id is initial.
      get reference of task_id_counter into requested_task_id.
    else.
      create data requested_task_id.
      requested_task_id->* = request_task_id.
    endif.

    if requested_task_id->* gt ( lines( random_numbers ) div partition_size ).
      return.
    else.
      task_id = requested_task_id->*.
    endif.

    data(input) = cast input_object( zif_proota_parallel_code~create_context_input_object( ) ).

    loop at random_numbers reference into data(number)
      from requested_task_id->* * partition_size + 1
      to ( requested_task_id->* + 1 ) * partition_size.
      append number->* to input->*.
    endloop.
    if sy-subrc eq 0.
      task_input = input.
      add 1 to requested_task_id->*.
      add 1 to statistics-tasks_created.
    else.
      clear task_id.
    endif.


  endmethod.
  method zif_proota_parallel_code~process_task_output.
    merge_partition( sorted_partition = cast output_object( task_output )->* ).
  endmethod.
  method zif_proota_parallel_code~worker.
    data(input_data) = cast input_object( input ).
    data(output_data) = cast output_object( output ).
    sort input_data->*.
    output_data->* = input_data->*.
  endmethod.
  method merge_partition.

    data:
      main_part_idx type i value 1,
      sort_part_idx type i value 1.

    read table:
      sorted_numbers reference into data(main_value) index main_part_idx,
      sorted_partition reference into data(partition_value) index sort_part_idx.

    while partition_value is bound.
      while main_value is bound and
            main_value->* le partition_value->*.
        add 1 to main_part_idx.
        read table sorted_numbers reference into main_value index main_part_idx.
        if sy-subrc ne 0.
          clear main_value.
        endif.
      endwhile.
      insert partition_value->* into sorted_numbers index main_part_idx.
      add 1 to sort_part_idx.
      read table sorted_numbers reference into main_value index main_part_idx.
      read table sorted_partition reference into partition_value index sort_part_idx.
      if sy-subrc ne 0.
        clear partition_value.
      endif.
    endwhile.

  endmethod.

  method print_results.
    data(output) = cl_demo_output=>new( ).
    output->write_data( value = random_numbers name = conv #( 'Original data'(L01) ) ).
    output->write_data( value = sorted_numbers name = conv #( 'Sorted Data'(L02) ) ).
    output->write_data( value = statistics     name = conv #( 'Statistics'(L03) ) ).
    output->display( ).
  endmethod.
endclass.

parameters:
  randomqt type i default 20,
  partsize type i default 4,
  maxtasks type i default 5.

start-of-selection.

  data(parallel_sorting) = new lcl_parallel_sorting( ).
  parallel_sorting->init_data(
    random_numbers_to_generate = randomqt
    partition_size = partsize ).
  new zcl_proota_parallel_runner( parallel_sorting )->run( max_tasks = maxtasks ).
  parallel_sorting->print_results( ).
