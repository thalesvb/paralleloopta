class zcl_proota_parallel_runner definition
  public
  final
  create public .

  public section.

    methods constructor
      importing
        !parallel_code type ref to zif_proota_parallel_code .
    methods run .
  protected section.
  private section.

    data m_parallel_code type ref to zif_proota_parallel_code .
endclass.



class zcl_proota_parallel_runner implementation.


  method constructor.
    m_parallel_code = parallel_code.
  endmethod.


  method run.
    zcl_proota_framework=>run(
        parallel_code = m_parallel_code
    ).
  endmethod.
endclass.
