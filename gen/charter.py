import os
import sys

import plotly.graph_objects as go
import rapidjson


def get_benchmarks(filename: str):
    with open(os.path.join(sys.argv[1], filename)) as jsonfile:
        data = rapidjson.load(jsonfile)
    return [b for b in data["benchmarks"] if b["aggregate_name"] == "mean"]


def collect_data(
    measurement: str, compilers: list[str]
) -> tuple[list[list[float]], list[str]]:
    measures: list[list[float]] = []
    names: list[str] = []
    for compiler in compilers:
        benchmarks = get_benchmarks(f"results_{compiler.lower()}.json")
        measures.append([x[measurement] for x in benchmarks])
        if len(names) == 0:
            names = [x["run_name"] for x in benchmarks]
    return (measures, names)


def doit():
    compilers = ["GCC", "Clang", "MinGW", "MSVC"]
    measurements, names = collect_data("cpu_time", compilers)

    compilers = [*compilers, "Average"]
    measurements.append([sum(col) / len(col) for col in zip(*measurements)])

    fig = go.Figure(
        data=[
            go.Bar(name=compiler, x=names, y=measures)
            for compiler, measures in zip(compilers, measurements)
        ]
    )
    fig.update_layout(barmode="group")
    fig.show()


if __name__ == "__main__":
    doit()
