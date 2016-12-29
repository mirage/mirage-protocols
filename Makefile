all:
	ocaml pkg/pkg.ml build -n mirage-protocols -q
	ocaml pkg/pkg.ml build -n mirage-protocols-lwt -q

clean:
	ocaml pkg/pkg.ml clean -n mirage-protocols -q
	ocaml pkg/pkg.ml clean -n mirage-protocols-lwt -q
