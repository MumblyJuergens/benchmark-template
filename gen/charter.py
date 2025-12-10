import os
import sys

# import plotly.express as px
import plotly.graph_objects as go
import rapidjson


def get_data(filename: str):
    with open(os.path.join(sys.argv[1], filename)) as jsonfile:
        data = rapidjson.load(jsonfile)
    return data["benchmarks"]


def doit():
    gccdata = get_data("results_gcc.json")
    clangdata = get_data("results_clang.json")
    mingwdata = get_data("results_mingw.json")

    gccmean = [b for b in gccdata if b["aggregate_name"] == "mean"]
    clangmean = [b for b in clangdata if b["aggregate_name"] == "mean"]
    mingwmean = [b for b in mingwdata if b["aggregate_name"] == "mean"]

    def getme(who, what):
        return [x[what] for x in who]

    name = getme(gccmean, "run_name")

    fig = go.Figure(
        data=[
            go.Bar(name="GCC", x=name, y=getme(gccmean, "cpu_time")),
            go.Bar(name="Clang", x=name, y=getme(clangmean, "cpu_time")),
            go.Bar(name="MinGW", x=name, y=getme(mingwmean, "cpu_time")),
        ]
    )

    fig.update_layout(barmode="group")
    fig.show()


if __name__ == "__main__":
    doit()
