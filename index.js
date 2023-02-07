process.env["PATH"] = process.env["PATH"] + ":" + process.env["LAMBDA_TASK_ROOT"] + "/lib"
process.env["LD_LIBRARY_PATH"] = process.env["LAMBDA_TASK_ROOT"] + "/lib"
process.env["PKG_CONFIG_PATH"] = process.env["LAMBDA_TASK_ROOT"] + "/lib"

const { ChartJSNodeCanvas } = require('chartjs-node-canvas')
const fs = require('fs')

const create = async () => {
  const timesInMs = [1, 2, 3]
  const values =  [1, 2, 3]

  console.log(process.env.PATH)
  console.log(process.env.LD_LIBRARY_PATH)
  console.log(process.env.PKG_CONFIG_PATH)

  const data = {
    labels: timesInMs,
    datasets: [
      {
        data: values,
        fill: false,
        borderColor: '#900e2c',
      },
    ],
  }

  const config = {
    type: 'line',
    data,
    options: {
      plugins: {
        legend: false,
        title: {
          text: 'Test',
          display: true,
        },
      },
    },
  }

  const chartNode = new ChartJSNodeCanvas({
    width: 1200,
    height: 300,
    backgroundColour: 'white',
  })

  const buffer = await chartNode.renderToBuffer(config)
  fs.writeFileSync('test.png', buffer, 'base64')
}

create()
