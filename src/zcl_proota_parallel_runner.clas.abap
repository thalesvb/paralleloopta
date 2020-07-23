class zcl_proota_parallel_runner definition
  public
  final
  create public.

  public section.
    methods constructor
      importing
        code type ref to zif_proota_parallel_code.
    methods run
      importing max_tasks type i optional
                server_group type spta_rfcgr default 'parallel_generators'.
  protected section.
  private section.
    data parallel_code type ref to zif_proota_parallel_code.
endclass.

class zcl_proota_parallel_runner implementation.

  method constructor.
    parallel_code = code.
  endmethod.

  method run.
    zcl_proota_framework=>run(
        parallel_code = parallel_code
        max_tasks = max_tasks ).
  endmethod.
endclass.
