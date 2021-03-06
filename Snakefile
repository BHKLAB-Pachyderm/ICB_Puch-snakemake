from snakemake.remote.S3 import RemoteProvider as S3RemoteProvider
S3 = S3RemoteProvider(
    access_key_id=config["key"], 
    secret_access_key=config["secret"],
    host=config["host"],
    stay_on_remote=False
)
prefix = config["prefix"]
filename = config["filename"]
data_source  = "https://raw.githubusercontent.com/BHKLAB-Pachyderm/ICB_Puch-data/main/"

rule get_MultiAssayExp:
    output:
        S3.remote(prefix + filename)
    input:
        S3.remote(prefix + "processed/cased_sequenced.csv"),
        S3.remote(prefix + "processed/CLIN.csv"),
        S3.remote(prefix + "processed/EXPR.csv"),
        S3.remote(prefix + "annotation/Gencode.v19.annotation.RData")
    resources:
        mem_mb=3000
    shell:
        """
        Rscript -e \
        '
        load(paste0("{prefix}", "annotation/Gencode.v19.annotation.RData"))
        source("https://raw.githubusercontent.com/BHKLAB-Pachyderm/ICB_Common/main/code/get_MultiAssayExp.R");
        saveRDS(
            get_MultiAssayExp(study = "Puch", input_dir = paste0("{prefix}", "processed")), 
            "{prefix}{filename}"
        );
        '
        """

rule download_annotation:
    output:
        S3.remote(prefix + "annotation/Gencode.v19.annotation.RData")
    shell:
        """
        wget https://github.com/BHKLAB-Pachyderm/Annotations/blob/master/Gencode.v19.annotation.RData?raw=true -O {prefix}annotation/Gencode.v19.annotation.RData 
        """

rule format_data:
    output:
        S3.remote(prefix + "processed/cased_sequenced.csv"),
        S3.remote(prefix + "processed/CLIN.csv"),
        S3.remote(prefix + "processed/EXPR.csv")
    input:
        S3.remote(prefix + "download/mel_puch_exp_data.csv"),
        S3.remote(prefix + "download/mel_puch_survival_data.csv"),
        S3.remote(prefix + "download/mel_puch_clin_data.csv")
    resources:
        mem_mb=1000
    shell:
        """
        Rscript scripts/Format_Data.R \
        {prefix}download \
        {prefix}processed \
        """

rule download_data:
    output:
        S3.remote(prefix + "download/mel_puch_exp_data.csv"),
        S3.remote(prefix + "download/mel_puch_survival_data.csv"),
        S3.remote(prefix + "download/mel_puch_clin_data.csv")
    resources:
        mem_mb=1000
    shell:
        """
        wget {data_source}mel_puch_exp_data.csv -O {prefix}download/mel_puch_exp_data.csv
        wget {data_source}mel_puch_survival_data.csv -O {prefix}download/mel_puch_survival_data.csv
        wget {data_source}mel_puch_clin_data.csv -O {prefix}download/mel_puch_clin_data.csv
        """ 