require("dotenv").config();
import * as path from "path";

export class CompilerConfiguration {
  public readonly contractSourceRoot: string;
  // TODO:add flattener contract output dir
  public readonly flattenContractOutputRoot: string;
  public readonly outputRoot: string;
  public readonly contractInterfacesOutputPath: string;
  public readonly abiOutputPath: string;
  public readonly contractOutputPath: string;
// TODO:add flattener contract output dir
  public constructor(contractSourceRoot: string, outputRoot: string,flattenContractOutputRoot:string) {
    this.contractSourceRoot = contractSourceRoot;
    this.flattenContractOutputRoot = flattenContractOutputRoot;// TODO:add flattener contract output dir
    this.outputRoot = outputRoot;
    this.contractInterfacesOutputPath = path.join(
      contractSourceRoot,
      "../libraries",
      "ContractInterfaces.ts"
    );
    this.abiOutputPath = path.join(outputRoot, "abi.json");
    this.contractOutputPath = path.join(outputRoot, "contracts.json");
  }

  public static create(): CompilerConfiguration {
    const contractSourceRoot = path.join(__dirname, "../../source/contracts/");
    const flattenContractOutputRoot = path.join(__dirname, "../../contracts_flattener/");
    const outputRoot =
      typeof process.env.OUTPUT_PATH === "undefined"
        ? path.join(__dirname, "../../output/contracts/")
        : path.normalize(<string>process.env.OUTPUT_ROOT);

    return new CompilerConfiguration(contractSourceRoot, outputRoot,flattenContractOutputRoot);
  }
}
